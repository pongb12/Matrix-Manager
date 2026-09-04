/*
 * FileSearcher.h — explicit, filter-based filesystem search (MM-031).
 *
 * TASK.md MM-031:
 *   - supports filename substring, extension, minimum and maximum size
 *   - never runs automatically; starts only on user action
 *   - runs on a worker thread with incremental results and cancellation
 *
 * Results are capped so a huge tree cannot exhaust memory; the summary
 * reports truncation honestly.
 */
#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QPointer>
#include <atomic>

class QThread;

class FileSearcher : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool running READ running NOTIFY runningChanged)

public:
    explicit FileSearcher(QObject *parent = nullptr);
    ~FileSearcher() override;

    // Any filter may be empty/unset; filters combine with AND.
    Q_INVOKABLE void start(const QString &rootPath,
                           const QString &nameContains,
                           const QString &extension,
                           quint64 minBytes,
                           quint64 maxBytes);
    Q_INVOKABLE void cancel();

    bool running() const { return m_running; }

signals:
    void runningChanged();
    void progressChanged(quint64 filesSeen);
    // Emitted periodically while scanning with the current snapshot.
    void partialResults(const QString &rootPath, const QVariantList &results);
    // Emitted once at the end (also when cancelled — check summary.cancelled).
    void finished(const QString &rootPath, const QVariantList &results,
                  const QVariantMap &summary);
    void failed(const QString &rootPath, const QString &message);

private:
    void runScan();

    QPointer<QThread> m_thread;
    std::atomic_bool m_cancel{false};
    std::atomic_bool m_running{false};
    std::atomic<quint64> m_filesSeen{0};

    // Worker-thread-only scan parameters (valid only while a scan runs).
    QString m_root;
    QString m_name;
    QString m_extension;
    quint64 m_minBytes = 0;
    quint64 m_maxBytes = 0;
};
