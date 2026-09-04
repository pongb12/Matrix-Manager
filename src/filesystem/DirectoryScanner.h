/*
 * DirectoryScanner.h — asynchronous directory usage scanner (MM-022).
 *
 * Computes the recursive size of every direct child of a root directory.
 * Requirements implemented:
 *   - on-demand only (never started automatically)
 *   - asynchronous worker thread, GUI never blocked
 *   - incremental partial results while scanning
 *   - cancellation
 *   - permission errors recorded per entry, scan continues
 *   - symlink safety (never follows by default, cycle guard when enabled)
 *
 * Runs on an internal QThread; results are delivered via queued signals.
 */
#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QPointer>
#include <atomic>

class QThread;
class FileWalker;

class DirectoryScanner : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool running READ running NOTIFY runningChanged)
    Q_PROPERTY(quint64 filesSeen READ filesSeen NOTIFY progressChanged)

public:
    explicit DirectoryScanner(QObject *parent = nullptr);
    ~DirectoryScanner() override;

    Q_INVOKABLE void start(const QString &rootPath);
    Q_INVOKABLE void cancel();

    bool running() const { return m_running; }
    quint64 filesSeen() const { return m_filesSeen; }

signals:
    void runningChanged();
    void progressChanged(quint64 filesSeen);
    // Emitted periodically while scanning with the current snapshot.
    void partialResults(const QString &rootPath, const QVariantList &entries);
    // Emitted once at the end (also when cancelled — check summary.cancelled).
    void finished(const QString &rootPath, const QVariantList &entries,
                  const QVariantMap &summary);
    void failed(const QString &rootPath, const QString &message);

private:
    struct ChildBucket
    {
        QString name;
        QString path;
        bool isDir = false;
        bool isSymlink = false;
        quint64 bytes = 0;
        quint64 files = 0;
        QString error;
    };

    void runScan(const QString &rootPath);
    QVariantList toVariantList() const;
    void emitProgress();

    QPointer<QThread> m_thread;
    std::atomic_bool m_cancel{false};
    std::atomic_bool m_running{false};
    std::atomic<quint64> m_filesSeen{0};

    // Worker-thread-only state (valid only while a scan runs).
    QVector<ChildBucket> *m_buckets = nullptr;
    QString m_scanRoot;
};
