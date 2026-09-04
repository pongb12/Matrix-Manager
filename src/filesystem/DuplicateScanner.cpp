#include "DuplicateScanner.h"
#include "FileWalker.h"
#include "core/SettingsService.h"

#include <QCryptographicHash>
#include <QDateTime>
#include <QDir>
#include <QElapsedTimer>
#include <QFile>
#include <QFileInfo>
#include <QThread>

#include <algorithm>
#include <unordered_map>
#include <vector>

namespace
{
constexpr int kProgressEmitEvery = 256;   // files
constexpr qsizetype kPartialHashBytes = 4096;
constexpr qint64 kHashChunkSize = 1024 * 1024;

QByteArray hashPrefix(const QString &path, qint64 bytes)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly))
        return {};
    return QCryptographicHash::hash(file.read(bytes),
                                    QCryptographicHash::Md5);
}

QByteArray hashFile(const QString &path)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly))
        return {};
    QCryptographicHash hash(QCryptographicHash::Md5);
    char buffer[kHashChunkSize];
    while (!file.atEnd()) {
        const qint64 read = file.read(buffer, kHashChunkSize);
        if (read < 0)
            return {};
        hash.addData(buffer, static_cast<int>(read));
    }
    return hash.result();
}
} // namespace

DuplicateScanner::DuplicateScanner(QObject *parent)
    : QObject(parent)
{
}

DuplicateScanner::~DuplicateScanner()
{
    if (m_running) {
        m_cancel = true;
        if (m_thread)
            m_thread->wait(30000);
    }
}

void DuplicateScanner::start(const QString &rootPath)
{
    if (m_running) {
        qWarning("DuplicateScanner: scan already in progress");
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
    m_hashedFiles = 0;
    m_reclaimableBytes = 0;
    m_running = true;
    emit runningChanged();

    auto *thread = QThread::create([this, rootPath] { runScan(rootPath); });
    connect(thread, &QThread::finished, thread, &QObject::deleteLater);
    m_thread = thread;
    thread->start();
}

void DuplicateScanner::cancel()
{
    m_cancel = true;
}

void DuplicateScanner::runScan(const QString &rootPath)
{
    const QString normalized = QDir(rootPath).absolutePath();
    m_scanRoot = normalized;

    // -------- pass 1: collect candidate files grouped by size ------------
    FileWalker walker;
    walker.setFollowSymlinks(SettingsService::instance()->followSymlinks());
    walker.setCrossFilesystems(SettingsService::instance()->crossFilesystems());

    std::unordered_map<quint64, std::vector<FileRecord>> bySize;
    QElapsedTimer throttle;
    throttle.start();
    int sinceProgress = 0;

    walker.walk(normalized,
                [this, &walker, &bySize, &throttle,
                 &sinceProgress](const QFileInfo &info, bool isSymLink) {
        if (isSymLink || info.isDir())
            return;
        const qint64 size = info.size();
        if (size <= 0)
            return; // empty files are "duplicates" of everything and worthless

        FileRecord record;
        record.path = info.absoluteFilePath();
        record.name = info.fileName();
        record.size = static_cast<quint64>(size);
        record.mtime = info.lastModified().toMSecsSinceEpoch();
        bySize[record.size].push_back(record);

        ++sinceProgress;
        if (sinceProgress >= kProgressEmitEvery) {
            sinceProgress = 0;
            m_filesSeen.store(walker.filesSeen());
            emit progressChanged(m_filesSeen.load());
        }
    });

    if (m_cancel)
        walker.cancel();

    // -------- pass 2+3: partial hash, then full hash where needed --------
    QVariantList groups;

    // Largest sizes first so the most valuable groups are ready early.
    std::vector<quint64> sizes;
    sizes.reserve(bySize.size());
    for (const auto &entry : bySize)
        if (entry.second.size() > 1)
            sizes.push_back(entry.first);
    std::sort(sizes.begin(), sizes.end(), std::greater<quint64>());

    std::vector<FileRecord> partialBucket;
    std::vector<FileRecord> fullBucket;

    for (const quint64 size : sizes) {
        if (m_cancel)
            break;
        const std::vector<FileRecord> &candidates = bySize[size];

        // partial hash splits candidates by the first 4 KiB
        std::unordered_map<QString, std::vector<FileRecord>> byPartial;
        for (const FileRecord &record : candidates) {
            if (m_cancel)
                break;
            const QByteArray digest = hashPrefix(record.path, kPartialHashBytes);
            if (digest.isEmpty())
                continue; // unreadable: skip honestly
            ++m_hashedFiles;
            byPartial[QString::fromLatin1(digest.toHex())].push_back(record);
            if (++sinceProgress >= kProgressEmitEvery) {
                sinceProgress = 0;
                emit progressChanged(m_filesSeen.load());
            }
        }

        for (auto &partialGroup : byPartial) {
            if (m_cancel)
                break;
            if (partialGroup.second.size() < 2)
                continue;

            // full hash only where partial hashes collide
            std::unordered_map<QString, std::vector<FileRecord>> byFull;
            for (const FileRecord &record : partialGroup.second) {
                if (m_cancel)
                    break;
                const QByteArray digest = hashFile(record.path);
                if (digest.isEmpty())
                    continue;
                ++m_hashedFiles;
                byFull[QString::fromLatin1(digest.toHex())].push_back(record);
            }

            for (auto &fullGroup : byFull) {
                if (fullGroup.second.size() < 2)
                    continue;

                // oldest first: a natural "keep" recommendation for the UI
                std::sort(fullGroup.second.begin(), fullGroup.second.end(),
                          [](const FileRecord &a, const FileRecord &b) {
                    if (a.mtime != b.mtime)
                        return a.mtime < b.mtime;
                    return a.name.toLower() < b.name.toLower();
                });

                QVariantList files;
                for (const FileRecord &record : fullGroup.second) {
                    QVariantMap fm;
                    fm.insert(QStringLiteral("name"), record.name);
                    fm.insert(QStringLiteral("path"), record.path);
                    fm.insert(QStringLiteral("size"), record.size);
                    fm.insert(QStringLiteral("mtime"), record.mtime);
                    files.append(fm);
                }

                QVariantMap group;
                group.insert(QStringLiteral("hash"),
                             fullGroup.first.left(12)); // hex prefix, for reference only
                group.insert(QStringLiteral("size"), size);
                group.insert(QStringLiteral("files"), files);
                group.insert(QStringLiteral("wasted"),
                             size * (fullGroup.second.size() - 1));
                groups.append(group);
                m_reclaimableBytes += size * (fullGroup.second.size() - 1);
            }
        }

        if (throttle.elapsed() > 200) {
            throttle.restart();
            emit progressChanged(m_filesSeen.load());
        }
    }

    QVariantMap summary;
    summary.insert(QStringLiteral("scannedFiles"), walker.filesSeen());
    summary.insert(QStringLiteral("hashedFiles"), m_hashedFiles);
    summary.insert(QStringLiteral("groupCount"), groups.size());
    summary.insert(QStringLiteral("reclaimableBytes"), m_reclaimableBytes);
    summary.insert(QStringLiteral("errorCount"), walker.errors().size());
    summary.insert(QStringLiteral("cancelled"), m_cancel || walker.wasCancelled());
    summary.insert(QStringLiteral("rootPath"), m_scanRoot);

    QVariantList ordered = groups;

    m_running = false;
    emit runningChanged();
    emit finished(m_scanRoot, ordered, summary);
}
