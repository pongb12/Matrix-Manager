/*
 * FileWalker.h — shared, safety-first directory traversal.
 *
 * Implements the filesystem rules from DOC.md rule 8 and AGENT.md rule 11:
 *   - symbolic links are never followed recursively by default
 *   - an inaccessible entry must not abort the whole scan
 *   - special files (devices, sockets, FIFOs) are not treated as user files
 *   - scans stay inside one filesystem unless explicitly allowed
 *
 * The walker is synchronous and single-threaded; callers run it on their own
 * worker thread. It is cancellable and reports per-entry problems instead of
 * failing wholesale.
 */
#pragma once

#include <QString>
#include <QStringList>
#include <QFileInfo>
#include <functional>

class FileWalker
{
public:
    // Called for every regular file or symlink encountered.
    //   info        — the entry's file information
    //   isSymLink   — true for symlinks (never recursed into)
    using VisitFn = std::function<void(const QFileInfo &info, bool isSymLink)>;

    FileWalker() = default;

    void setFollowSymlinks(bool value) { m_followSymlinks = value; }
    void setCrossFilesystems(bool value) { m_crossFilesystems = value; }

    void cancel() { m_cancelled = true; }
    bool wasCancelled() const { return m_cancelled; }

    quint64 filesSeen() const { return m_filesSeen; }
    quint64 specialFilesSkipped() const { return m_specialSkipped; }

    // Collected problems, formatted as "path: reason". Capped so that a
    // huge unreadable tree cannot exhaust memory.
    const QStringList &errors() const { return m_errors; }
    int suppressedErrorCount() const { return m_suppressedErrors; }

    /*
     * Traverses rootPath depth-first. Returns true if the root itself could
     * be read, false when the root is inaccessible. Directories the process
     * cannot read are reported via errors() and skipped.
     */
    bool walk(const QString &rootPath, const VisitFn &visit);

private:
    void recordError(const QString &path, const QString &reason);

    bool m_followSymlinks = false;
    bool m_crossFilesystems = false;
    bool m_cancelled = false;
    quint64 m_filesSeen = 0;
    quint64 m_specialSkipped = 0;
    int m_suppressedErrors = 0;
    QStringList m_errors;

    static constexpr int kMaxErrors = 400;
};
