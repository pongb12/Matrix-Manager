#include "ActivityLog.h"

#include <algorithm>

ActivityLog *ActivityLog::instance()
{
    static ActivityLog log;
    return &log;
}

ActivityLog::ActivityLog(QObject *parent)
    : QObject(parent)
{
}

void ActivityLog::add(const QString &message, const QString &detail)
{
    Entry entry;
    entry.timestamp = QDateTime::currentDateTime();
    entry.message = message;
    entry.detail = detail;
    m_entries.prepend(entry);
    if (m_entries.size() > kMaxEntries)
        m_entries.removeLast();
    emit entriesChanged();
}

QVariantList ActivityLog::entries() const
{
    QVariantList list;
    list.reserve(m_entries.size());
    for (const Entry &e : m_entries) {
        QVariantMap map;
        map.insert(QStringLiteral("timestamp"), e.timestamp.toUTC());
        map.insert(QStringLiteral("message"), e.message);
        map.insert(QStringLiteral("detail"), e.detail);
        list.append(map);
    }
    return list;
}

void ActivityLog::clear()
{
    if (m_entries.isEmpty())
        return;
    m_entries.clear();
    emit entriesChanged();
}
