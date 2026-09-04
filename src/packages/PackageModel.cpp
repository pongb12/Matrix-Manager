#include "PackageModel.h"

#include <algorithm>

PackageModel::PackageModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int PackageModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_view.size();
}

QVariant PackageModel::data(const QModelIndex &index, int role) const
{
    if (index.row() < 0 || index.row() >= m_view.size())
        return {};
    const PackageEntry &entry = m_entries.at(m_view.at(index.row()));

    switch (role) {
    case PackageNameRole:
        return entry.name;
    case DisplayNameRole:
        return entry.summary.isEmpty() ? entry.name : entry.summary;
    case VersionRole:
        return entry.version;
    case ArchitectureRole:
        return entry.architecture;
    case SizeRole:
        return entry.installedSizeBytes;
    case SummaryRole:
        return entry.summary;
    case SectionRole:
        return entry.section;
    default:
        return {};
    }
}

QHash<int, QByteArray> PackageModel::roleNames() const
{
    return {
        { PackageNameRole, "packageName" },
        { DisplayNameRole, "displayName" },
        { VersionRole, "version" },
        { ArchitectureRole, "architecture" },
        { SizeRole, "size" },
        { SummaryRole, "summary" },
        { SectionRole, "section" }
    };
}

quint64 PackageModel::totalInstalledBytes() const
{
    quint64 total = 0;
    for (const PackageEntry &entry : m_entries)
        total += entry.installedSizeBytes;
    return total;
}

void PackageModel::resetFrom(QVector<PackageEntry> entries)
{
    beginResetModel();
    m_entries = std::move(entries);
    applyView();
    endResetModel();
    emit countChanged();
}

void PackageModel::setFilter(const QString &text)
{
    if (text == m_filter)
        return;
    m_filter = text;
    beginResetModel();
    applyView();
    endResetModel();
}

void PackageModel::sortBy(int role, bool ascending)
{
    m_sortRole = role;
    m_sortAscending = ascending;
    beginResetModel();
    applyView();
    endResetModel();
}

void PackageModel::applyView()
{
    m_view.clear();
    m_view.reserve(m_entries.size());
    for (int i = 0; i < m_entries.size(); ++i) {
        if (m_filter.isEmpty())
            m_view.append(i);
        else {
            const PackageEntry &entry = m_entries.at(i);
            if (entry.name.contains(m_filter, Qt::CaseInsensitive)
                || entry.summary.contains(m_filter, Qt::CaseInsensitive))
                m_view.append(i);
        }
    }

    std::stable_sort(m_view.begin(), m_view.end(),
                     [this](int a, int b) {
        const PackageEntry &ea = m_entries.at(a);
        const PackageEntry &eb = m_entries.at(b);
        int cmp = 0;
        switch (m_sortRole) {
        case PackageNameRole:
        case DisplayNameRole:
            cmp = QString::compare(ea.name.toLower(), eb.name.toLower());
            break;
        case VersionRole:
            cmp = QString::compare(ea.version, eb.version);
            break;
        case SizeRole:
        default:
            cmp = ea.installedSizeBytes < eb.installedSizeBytes
                      ? -1
                      : (ea.installedSizeBytes == eb.installedSizeBytes ? 0 : 1);
            break;
        }
        return m_sortAscending ? cmp < 0 : cmp > 0;
    });
}

QVariantMap PackageModel::get(int row) const
{
    QVariantMap map;
    if (row < 0 || row >= m_view.size())
        return map;
    const PackageEntry &entry = m_entries.at(m_view.at(row));
    map.insert(QStringLiteral("packageName"), entry.name);
    map.insert(QStringLiteral("displayName"),
               entry.summary.isEmpty() ? entry.name : entry.summary);
    map.insert(QStringLiteral("version"), entry.version);
    map.insert(QStringLiteral("architecture"), entry.architecture);
    map.insert(QStringLiteral("size"), entry.installedSizeBytes);
    map.insert(QStringLiteral("summary"), entry.summary);
    map.insert(QStringLiteral("section"), entry.section);
    return map;
}
