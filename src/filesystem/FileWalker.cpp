#include "FileWalker.h"

#include <QDir>
#include <QSet>

#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

namespace
{

// Returns the device id of a path, or 0 when it cannot be determined.
dev_t deviceOf(const QString &path, bool followSymlinks)
{
    struct stat st;
    const int rc = followSymlinks ? ::stat(QFile::encodeName(path).constData(), &st)
                                  : ::lstat(QFile::encodeName(path).constData(), &st);
    return rc == 0 ? st.st_dev : 0;
}

// Returns inode number for cycle detection when following symlinks.
ino_t inodeOf(const QString &path)
{
    struct stat st;
    if (::stat(QFile::encodeName(path).constData(), &st) != 0)
        return 0;
    return st.st_ino;
}

bool isReadableDir(const QString &path)
{
    return ::access(QFile::encodeName(path).constData(), R_OK | X_OK) == 0;
}

struct StackItem
{
    QString path;
    qint64 depth;
};

constexpr qint64 kMaxDepth = 128;

} // namespace

bool FileWalker::walk(const QString &rootPath, const VisitFn &visit)
{
    m_cancelled = false;
    m_filesSeen = 0;
    m_specialSkipped = 0;
    m_suppressedErrors = 0;
    m_errors.clear();

    const QFileInfo rootInfo(rootPath);
    if (!rootInfo.exists() || !rootInfo.isDir()) {
        recordError(rootPath, QStringLiteral("Directory does not exist"));
        return false;
    }
    if (!isReadableDir(rootPath)) {
        recordError(rootPath, QStringLiteral("Permission denied"));
        return false;
    }

    const dev_t rootDevice = deviceOf(rootPath, false);
    QSet<QString> visitedInodes; // "dev:inode" guard for symlinked dirs

    QVector<StackItem> stack;
    stack.append({ rootPath, 0 });

    while (!stack.isEmpty()) {
        if (m_cancelled)
            break;

        const StackItem item = stack.takeLast();
        const QDir dir(item.path);

        const QFileInfoList entries =
            dir.entryInfoList(QDir::AllEntries | QDir::Hidden | QDir::NoDotAndDotDot,
                              QDir::Unsorted);
        if (entries.isEmpty() && !isReadableDir(item.path)) {
            // Some unreadable directories return an empty list without error.
            recordError(item.path, QStringLiteral("Permission denied"));
            continue;
        }

        for (const QFileInfo &info : entries) {
            if (m_cancelled)
                break;

            if (info.isSymLink()) {
                ++m_filesSeen;
                visit(info, true);

                // Only descend into symlinked directories when the user
                // explicitly enabled it, and only with cycle protection.
                if (m_followSymlinks) {
                    const QFileInfo target(info.symLinkTarget());
                    if (target.isDir()) {
                        const dev_t dev = deviceOf(info.absoluteFilePath(), true);
                        const ino_t ino = inodeOf(info.absoluteFilePath());
                        const QString key = QStringLiteral("%1:%2").arg(dev).arg(ino);
                        if (visitedInodes.contains(key)) {
                            recordError(info.absoluteFilePath(),
                                        QStringLiteral("Symlink cycle detected, skipped"));
                            continue;
                        }
                        if (!m_crossFilesystems && dev != rootDevice && dev != 0) {
                            recordError(info.absoluteFilePath(),
                                        QStringLiteral("Different filesystem (mounted volume)"));
                            continue;
                        }
                        visitedInodes.insert(key);
                        if (item.depth < kMaxDepth)
                            stack.append({ info.absoluteFilePath(), item.depth + 1 });
                    }
                }
                continue;
            }

            if (info.isDir()) {
                // Mounted-volume boundary check (conservative by default).
                const dev_t dev = deviceOf(info.absoluteFilePath(), false);
                if (!m_crossFilesystems && dev != rootDevice && dev != 0) {
                    ++m_filesSeen;
                    visit(info, false); // visited but not traversed
                    recordError(info.absoluteFilePath(),
                                QStringLiteral("Different filesystem (mounted volume), not traversed"));
                    continue;
                }
                if (isReadableDir(info.absoluteFilePath())) {
                    if (item.depth < kMaxDepth)
                        stack.append({ info.absoluteFilePath(), item.depth + 1 });
                } else {
                    ++m_filesSeen;
                    visit(info, false);
                    recordError(info.absoluteFilePath(), QStringLiteral("Permission denied"));
                }
                continue;
            }

            if (info.isFile()) {
                ++m_filesSeen;
                visit(info, false);
                continue;
            }

            // Devices, sockets, FIFOs etc. are not user files (DOC.md rule 8).
            ++m_specialSkipped;
        }
    }

    return true;
}

void FileWalker::recordError(const QString &path, const QString &reason)
{
    if (m_errors.size() >= kMaxErrors) {
        ++m_suppressedErrors;
        return;
    }
    m_errors.append(QStringLiteral("%1: %2").arg(path, reason));
}
