#include "DirectoryScanner.h"
#include "FileWalker.h"
#include "core/SettingsService.h"

#include <QDir>
#include <QThread>
#include <QElapsedTimer>

#include <algorithm>
#include <unordered_map>

namespace
{
constexpr int kProgressEmitEvery = 512;  // files
constexpr int kPartialEmitEvery = 4096;  // files
}

DirectoryScanner::DirectoryScanner(QObject *parent)
    : QObject(parent)
{
}

DirectoryScanner::~DirectoryScanner()
{
    if (m_running) {
        m_cancel = true;
        if (m_thread)
            m_thread->wait(10000);
    }
}

void DirectoryScanner::start(const QString &rootPath)
{
    if (m_running) {
        qWarning("DirectoryScanner: scan already in progress");
        return;
    }
    if (rootPath.isEmpty())
        return;

    const QDir dir(rootPath);
    if (!dir.exists() || !dir.isReadable()) {
        emit failed(rootPath,
                    QStringLiteral("Directory does not exist or is not readable"));
        return;
    }

    m_cancel = false;
    m_filesSeen = 0;
    m_running = true;
    emit runningChanged();

    auto *thread = QThread::create([this, rootPath] { runScan(rootPath); });
    connect(thread, &QThread::finished, thread, &QObject::deleteLater);
    m_thread = thread;
    thread->start();
}

void DirectoryScanner::cancel()
{
    m_cancel = true;
}

void DirectoryScanner::runScan(const QString &rootPath)
{
    const QString normalized = QDir(rootPath).absolutePath();

    // One bucket per direct child of the root; a child's bytes accumulate
    // from every file found underneath it.
    QVector<ChildBucket> buckets;
    const QFileInfoList children =
        QDir(normalized).entryInfoList(QDir::AllEntries | QDir::Hidden
                                           | QDir::NoDotAndDotDot,
                                       QDir::Name | QDir::IgnoreCase);
    buckets.reserve(children.size());
    std::unordered_map<QString, int> bucketIndex;

    for (const QFileInfo &child : children) {
        ChildBucket bucket;
        bucket.name = child.fileName();
        bucket.path = child.absoluteFilePath();
        bucket.isDir = child.isDir() && !child.isSymLink();
        bucket.isSymlink = child.isSymLink();
        bucketIndex.emplace(bucket.name, static_cast<int>(buckets.size()));
        buckets.append(bucket);
    }

    m_buckets = &buckets;
    m_scanRoot = normalized;

    FileWalker walker;
    walker.setFollowSymlinks(SettingsService::instance()->followSymlinks());
    walker.setCrossFilesystems(SettingsService::instance()->crossFilesystems());

    QElapsedTimer throttle;
    throttle.start();
    int sinceProgress = 0;
    int sincePartial = 0;

    walker.walk(normalized,
                [this, &walker, &normalized, &bucketIndex, &buckets, &throttle,
                 &sinceProgress, &sincePartial](const QFileInfo &info, bool isSymLink) {
        if (m_cancel)
            return;

        // Map the visited path to its top-level child bucket.
        QString relative = info.absoluteFilePath();
        if (relative.startsWith(normalized + QLatin1Char('/')))
            relative = relative.mid(normalized.size() + 1);
        const int slash = relative.indexOf(QLatin1Char('/'));
        const QString topLevel = (slash == -1) ? relative : relative.left(slash);

        auto it = bucketIndex.find(topLevel);
        if (it == bucketIndex.end())
            return;
        ChildBucket &bucket = buckets[it->second];

        if (isSymLink)
            return; // symlinks are listed but contribute no target content
        if (info.isDir())
            return; // directories accumulate through their files

        bucket.bytes += static_cast<quint64>(info.size());
        ++bucket.files;

        ++sinceProgress;
        ++sincePartial;
        if (sinceProgress >= kProgressEmitEvery) {
            sinceProgress = 0;
            m_filesSeen.store(walker.filesSeen());
            emit progressChanged(m_filesSeen.load());
        }
        if (sincePartial >= kPartialEmitEvery && throttle.elapsed() > 300) {
            sincePartial = 0;
            throttle.restart();
            emit partialResults(m_scanRoot, toVariantList());
        }
    });

    // Merge walker errors into buckets for honest reporting.
    const QStringList errors = walker.errors();
    for (const QString &error : errors) {
        const int colon = error.indexOf(QLatin1String(": "));
        if (colon <= 0)
            continue;
        const QString path = error.left(colon);
        QString relative = path;
        if (relative.startsWith(normalized + QLatin1Char('/')))
            relative = relative.mid(normalized.size() + 1);
        const int slash = relative.indexOf(QLatin1Char('/'));
        const QString topLevel = (slash == -1) ? relative : relative.left(slash);
        auto it = bucketIndex.find(topLevel);
        if (it != bucketIndex.end()) {
            ChildBucket &bucket = buckets[it->second];
            if (bucket.error.isEmpty())
                bucket.error = QStringLiteral("Contains inaccessible entries");
        }
    }

    std::sort(buckets.begin(), buckets.end(),
              [](const ChildBucket &a, const ChildBucket &b) {
        if (a.bytes != b.bytes)
            return a.bytes > b.bytes; // size descending
        return a.name.toLower() < b.name.toLower();
    });

    QVariantMap summary;
    quint64 totalBytes = 0;
    quint64 totalFiles = 0;
    for (const ChildBucket &bucket : buckets) {
        totalBytes += bucket.bytes;
        totalFiles += bucket.files;
    }
    summary.insert(QStringLiteral("totalBytes"), totalBytes);
    summary.insert(QStringLiteral("totalFiles"), totalFiles);
    summary.insert(QStringLiteral("errorCount"), errors.size());
    summary.insert(QStringLiteral("specialFilesSkipped"),
                   static_cast<quint64>(walker.specialFilesSkipped()));
    summary.insert(QStringLiteral("cancelled"), walker.wasCancelled());
    summary.insert(QStringLiteral("rootPath"), m_scanRoot);

    const QVariantList finalEntries = toVariantList();

    m_buckets = nullptr;
    m_running = false;
    emit runningChanged();
    emit finished(m_scanRoot, finalEntries, summary);
}

QVariantList DirectoryScanner::toVariantList() const
{
    if (!m_buckets)
        return {};
    QVariantList list;
    list.reserve(m_buckets->size());
    for (const ChildBucket &bucket : *m_buckets) {
        QVariantMap map;
        map.insert(QStringLiteral("name"), bucket.name);
        map.insert(QStringLiteral("path"), bucket.path);
        map.insert(QStringLiteral("isDir"), bucket.isDir);
        map.insert(QStringLiteral("isSymlink"), bucket.isSymlink);
        map.insert(QStringLiteral("bytes"), bucket.bytes);
        map.insert(QStringLiteral("files"), bucket.files);
        map.insert(QStringLiteral("error"), bucket.error);
        list.append(map);
    }
    return list;
}
