#include "PackageModel.h"

#include <QHash>
#include <algorithm>

namespace
{
// Category ids in their fixed display order. The view always sorts by this
// rank first so that a ListView can render the list as category sections.
const char *const kCategoryOrder[] = {
    "accessories", "internet", "development", "graphics", "multimedia",
    "games", "science", "system", "libraries", "fonts", "desktop", "other"
};

int categoryRank(const QString &id)
{
    for (int i = 0; i < int(sizeof(kCategoryOrder) / sizeof(kCategoryOrder[0])); ++i) {
        if (id == QLatin1String(kCategoryOrder[i]))
            return i;
    }
    return int(sizeof(kCategoryOrder) / sizeof(kCategoryOrder[0])); // unknown -> last
}

// dpkg section -> category id. Debian sections are matched on the base name;
// Ubuntu/Mint prefixes ("universe/", "multiverse/", "contrib/", "non-free/")
// are stripped first. Anything unmapped (and empty sections) lands in
// "other" so no package is ever hidden from the list.
const QHash<QString, QString> &sectionCategoryMap()
{
    static const QHash<QString, QString> map = {
        // Accessories
        {QStringLiteral("utils"),     QStringLiteral("accessories")},
        {QStringLiteral("misc"),      QStringLiteral("accessories")},
        {QStringLiteral("shells"),    QStringLiteral("accessories")},
        {QStringLiteral("text"),      QStringLiteral("accessories")},
        {QStringLiteral("editors"),   QStringLiteral("accessories")},
        {QStringLiteral("intro"),     QStringLiteral("accessories")},
        // Internet
        {QStringLiteral("net"),       QStringLiteral("internet")},
        {QStringLiteral("web"),       QStringLiteral("internet")},
        {QStringLiteral("comm"),      QStringLiteral("internet")},
        {QStringLiteral("mail"),      QStringLiteral("internet")},
        {QStringLiteral("news"),      QStringLiteral("internet")},
        // Development
        {QStringLiteral("devel"),       QStringLiteral("development")},
        {QStringLiteral("libdevel"),    QStringLiteral("development")},
        {QStringLiteral("interpreters"),QStringLiteral("development")},
        {QStringLiteral("python"),      QStringLiteral("development")},
        {QStringLiteral("ruby"),        QStringLiteral("development")},
        {QStringLiteral("golang"),      QStringLiteral("development")},
        {QStringLiteral("javascript"),  QStringLiteral("development")},
        {QStringLiteral("rust"),        QStringLiteral("development")},
        {QStringLiteral("php"),         QStringLiteral("development")},
        {QStringLiteral("perl"),        QStringLiteral("development")},
        {QStringLiteral("lisp"),        QStringLiteral("development")},
        {QStringLiteral("ocaml"),       QStringLiteral("development")},
        {QStringLiteral("haskell"),     QStringLiteral("development")},
        {QStringLiteral("vcs"),         QStringLiteral("development")},
        // Graphics / Multimedia / Games
        {QStringLiteral("graphics"),  QStringLiteral("graphics")},
        {QStringLiteral("sound"),     QStringLiteral("multimedia")},
        {QStringLiteral("video"),     QStringLiteral("multimedia")},
        {QStringLiteral("games"),     QStringLiteral("games")},
        {QStringLiteral("toys"),      QStringLiteral("games")},
        // Science & education
        {QStringLiteral("science"),   QStringLiteral("science")},
        {QStringLiteral("math"),      QStringLiteral("science")},
        {QStringLiteral("education"), QStringLiteral("science")},
        {QStringLiteral("doc"),       QStringLiteral("science")},
        {QStringLiteral("tex"),       QStringLiteral("science")},
        // System
        {QStringLiteral("admin"),      QStringLiteral("system")},
        {QStringLiteral("base"),       QStringLiteral("system")},
        {QStringLiteral("kernel"),     QStringLiteral("system")},
        {QStringLiteral("otherosfs"),  QStringLiteral("system")},
        {QStringLiteral("embedded"),   QStringLiteral("system")},
        {QStringLiteral("x11"),        QStringLiteral("system")},
        {QStringLiteral("electronics"),QStringLiteral("system")},
        {QStringLiteral("hamradio"),   QStringLiteral("system")},
        // Libraries / Fonts / Desktop environments
        {QStringLiteral("libs"),      QStringLiteral("libraries")},
        {QStringLiteral("oldlibs"),   QStringLiteral("libraries")},
        {QStringLiteral("fonts"),     QStringLiteral("fonts")},
        {QStringLiteral("gnome"),     QStringLiteral("desktop")},
        {QStringLiteral("kde"),       QStringLiteral("desktop")},
        {QStringLiteral("xfce"),      QStringLiteral("desktop")},
        {QStringLiteral("lxde"),      QStringLiteral("desktop")},
    };
    return map;
}
} // namespace

QString PackageModel::categoryIdForSection(const QString &section)
{
    // "universe/utils" -> "utils"; "non-free/gnome" -> "gnome".
    const QString base = section.section(QLatin1Char('/'), -1).trimmed().toLower();
    if (base.isEmpty())
        return QStringLiteral("other");
    return sectionCategoryMap().value(base, QStringLiteral("other"));
}

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
    case CategoryIdRole:
        return categoryIdForSection(entry.section);
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
        { SectionRole, "section" },
        { CategoryIdRole, "categoryId" }
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

void PackageModel::setCategory(const QString &categoryId)
{
    if (categoryId == m_category)
        return;
    m_category = categoryId;
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
    const bool categoryActive = !m_category.isEmpty()
                                && m_category != QLatin1String("all");

    m_view.clear();
    m_view.reserve(m_entries.size());
    for (int i = 0; i < m_entries.size(); ++i) {
        const PackageEntry &entry = m_entries.at(i);
        if (categoryActive
            && categoryIdForSection(entry.section) != m_category)
            continue;
        if (!m_filter.isEmpty()
            && !entry.name.contains(m_filter, Qt::CaseInsensitive)
            && !entry.summary.contains(m_filter, Qt::CaseInsensitive)
            && !entry.section.contains(m_filter, Qt::CaseInsensitive))
            continue;
        m_view.append(i);
    }

    // Category first (so the list sections cleanly), then the user's sort
    // inside each group. stable_sort keeps name ties in dpkg order.
    std::stable_sort(m_view.begin(), m_view.end(),
                     [this](int a, int b) {
        const PackageEntry &ea = m_entries.at(a);
        const PackageEntry &eb = m_entries.at(b);
        const QString ca = categoryIdForSection(ea.section);
        const QString cb = categoryIdForSection(eb.section);
        if (ca != cb)
            return categoryRank(ca) < categoryRank(cb);
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

QVariantList PackageModel::categorySummary() const
{
    struct Agg { int count = 0; quint64 bytes = 0; };
    QHash<QString, Agg> agg;
    for (const PackageEntry &entry : m_entries) {
        Agg &slot = agg[categoryIdForSection(entry.section)];
        slot.count += 1;
        slot.bytes += entry.installedSizeBytes;
    }

    QVariantList out;
    for (const char *id : kCategoryOrder) {
        const auto it = agg.constFind(QLatin1String(id));
        if (it == agg.constEnd())
            continue;
        QVariantMap m;
        m.insert(QStringLiteral("id"), QLatin1String(id));
        m.insert(QStringLiteral("count"), it->count);
        m.insert(QStringLiteral("bytes"), it->bytes);
        out.append(m);
    }
    return out;
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
    map.insert(QStringLiteral("categoryId"), categoryIdForSection(entry.section));
    return map;
}
