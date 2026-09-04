#include "FileSearcher.h"
#include "FileWalker.h"
#include "core/SettingsService.h"

#include <QDir>
#include <QElapsedTimer>
#include <QThread>

#include <algorithm>

namespace
{
constexpr int kProgressEmitEvery = 512;   // files
constexpr int kPartialEmitEvery = 256;    // matches
constexpr int kMaxResults = 5000;
}

FileSearcher::FileSearcher(QObject *parent)
    : QObject(parent)
{
}

FileSearcher::~FileSearcher()
{
    if (m_running) {
        m_cancel = true;
        if (m_thread)
            m_thread->wait(10000);
    }
}

void FileSearcher::start(const QString &rootPath, const QString &nameContains,
                         const QString &extension, quint64 minBytes,
                         quint64 maxBytes)
{
    if (m_running) {
        qWarning("FileSearcher: search already in progress");
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

    m_root = QDir(rootPath).absolutePath();
    m_name = nameContains.trimmed();
    m_extension = extension.trimmed().toLower();
    if (m_extension.startsWith(QLatin1Char('.')))
        m_extension.remove(0, 1);
    m_minBytes = minBytes;
    m_maxBytes = maxBytes;

    m_cancel = false;
    m_filesSeen = 0;
    m_running = true;
    emit runningChanged();

    auto *thread = QThread::create([this] { runScan(); });
    connect(thread, &QThread::finished, thread, &QObject::deleteLater);
    m_thread = thread;
    thread->start();
}

void FileSearcher::cancel()
{
    m_cancel = true;
}

void FileSearcher::runScan()
{
    FileWalker walker;
    walker.setFollowSymlinks(SettingsService::instance()->followSymlinks());
    walker.setCrossFilesystems(SettingsService::instance()->crossFilesystems());

    QVariantList results;
    QVariantList snapshot;
    QElapsedTimer throttle;
    throttle.start();
    int sinceProgress = 0;
    bool truncated = false;

    const bool anyFilter = !m_name.isEmpty() || !m_extension.isEmpty()
                           || m_minBytes > 0 || m_maxBytes > 0;
    Q_UNUSED(anyFilter);

    walker.walk(m_root,
                [this, &walker, &results, &snapshot, &throttle,
                 &sinceProgress, &truncated](const QFileInfo &info, bool isSymLink) {
        if (isSymLink || info.isDir())
            return;
        const qint64 size = info.size();

        // Combined filters (TASK.md MM-031).
        if (m_minBytes > 0 && static_cast<quint64>(size) < m_minBytes)
            return;
        if (m_maxBytes > 0 && static_cast<quint64>(size) > m_maxBytes)
            return;
        if (!m_name.isEmpty()
                && !info.fileName().contains(m_name, Qt::CaseInsensitive))
            return;
        if (!m_extension.isEmpty()
                && info.suffix().toLower() != m_extension)
            return;

        QVariantMap map;
        map.insert(QStringLiteral("name"), info.fileName());
        map.insert(QStringLiteral("path"), info.absoluteFilePath());
        map.insert(QStringLiteral("size"), static_cast<quint64>(size));
        map.insert(QStringLiteral("mtime"),
                   info.lastModified().toMSecsSinceEpoch());
        results.append(map);
        snapshot.append(map);

        if (results.size() >= kMaxResults) {
            truncated = true;
            walker.cancel();
            return;
        }

        ++sinceProgress;
        if (sinceProgress >= kPartialEmitEvery && throttle.elapsed() > 300) {
            sinceProgress = 0;
            throttle.restart();
            emit partialResults(m_root, snapshot);
        }
    });

    QVariantMap summary;
    summary.insert(QStringLiteral("count"), results.size());
    summary.insert(QStringLiteral("scannedFiles"), walker.filesSeen());
    summary.insert(QStringLiteral("truncated"), truncated);
    summary.insert(QStringLiteral("errorCount"), walker.errors().size());
    summary.insert(QStringLiteral("cancelled"), m_cancel || walker.wasCancelled());
    summary.insert(QStringLiteral("rootPath"), m_root);

    // Largest first: for size-driven search this is what the user wants.
    std::sort(results.begin(), results.end(),
              [](const QVariant &a, const QVariant &b) {
        return a.toMap().value(QStringLiteral("size")).toULongLong()
             > b.toMap().value(QStringLiteral("size")).toULongLong();
    });

    m_running = false;
    emit runningChanged();
    emit finished(m_root, results, summary);
}
