/*
 * DuplicateScanner.h — content-based duplicate file detection (MM-032).
 *
 * Algorithm (TASK.md MM-032 — never hash every file blindly):
 *   1. walk the chosen root once, collecting regular files by size
 *   2. drop unique sizes (no possible duplicate)
 *   3. partial hash (first 4 KiB) to split the remaining groups
 *   4. full hash only for files whose partial hashes collide
 *
 * Runs on a worker thread like DirectoryScanner; results arrive once via
 * finished(). Nothing is ever deleted by this class — the UI moves selected
 * files to the trash through the existing safe path after confirmation.
 */
#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QPointer>
#include <atomic>

class QThread;

class DuplicateScanner : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool running READ running NOTIFY runningChanged)
    Q_PROPERTY(quint64 filesSeen READ filesSeen NOTIFY progressChanged)

public:
    explicit DuplicateScanner(QObject *parent = nullptr);
    ~DuplicateScanner() override;

    Q_INVOKABLE void start(const QString &rootPath);
    Q_INVOKABLE void cancel();

    bool running() const { return m_running; }
    quint64 filesSeen() const { return m_filesSeen; }

signals:
    void runningChanged();
    void progressChanged(quint64 filesSeen);
    // Emitted once at the end (also when cancelled — check summary.cancelled).
    void finished(const QString &rootPath, const QVariantList &groups,
                  const QVariantMap &summary);
    void failed(const QString &rootPath, const QString &message);

private:
    struct FileRecord
    {
        QString path;
        QString name;
        quint64 size = 0;
        qint64 mtime = 0;
    };

    void runScan(const QString &rootPath);

    QPointer<QThread> m_thread;
    std::atomic_bool m_cancel{false};
    std::atomic_bool m_running{false};
    std::atomic<quint64> m_filesSeen{0};

    // Worker-thread-only state (valid only while a scan runs).
    QString m_scanRoot;
    quint64 m_hashedFiles = 0;
    quint64 m_reclaimableBytes = 0;
};
