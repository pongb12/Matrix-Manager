/*
 * ActivityLog.h — in-memory record of actions performed during the current
 * Matrix Manager session (MM-061).
 *
 * This is NOT telemetry: nothing is persisted, nothing leaves the process.
 * It exists purely so the Overview page can show the user what this session
 * has done (e.g. "Deleted 1.4 GiB", "Uninstalled firefox").
 */
#pragma once

#include <QObject>
#include <QVector>
#include <QString>
#include <QDateTime>

class ActivityLog : public QObject
{
    Q_OBJECT

public:
    struct Entry
    {
        QDateTime timestamp;
        QString message;
        QString detail;
    };

    static ActivityLog *instance();

    // Newest-first list of QVariantMap { timestamp, message, detail }.
    Q_INVOKABLE QVariantList entries() const;
    Q_INVOKABLE void clear();

    void add(const QString &message, const QString &detail = {});

signals:
    void entriesChanged();

private:
    explicit ActivityLog(QObject *parent = nullptr);

    static constexpr int kMaxEntries = 200;
    QVector<Entry> m_entries;
};
