/*
 * PackageModel.h — data model for installed .deb packages (MM-041).
 *
 * 1.0.3-2: packages are grouped by a category derived from the dpkg
 * section (MM-042 browsing aid). The model keeps the view sorted by
 * category first so a ListView can render section headers, with the
 * user-selected sort applied inside each group. A search may also match
 * the section text ("web", "utils", ...).
 */
#pragma once

#include <QAbstractListModel>
#include <QString>
#include <QVector>

struct PackageEntry
{
    QString name;
    QString version;
    QString architecture;
    QString summary;     // one-line human description (display name source)
    QString section;     // dpkg section (e.g. "web", "utils")
    quint64 installedSizeBytes = 0;
};

class PackageModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(int totalCount READ totalCount NOTIFY countChanged)
    Q_PROPERTY(quint64 totalInstalledBytes READ totalInstalledBytes NOTIFY countChanged)

public:
    enum Roles
    {
        PackageNameRole = Qt::UserRole + 1,
        DisplayNameRole,
        VersionRole,
        ArchitectureRole,
        SizeRole,
        SummaryRole,
        SectionRole,
        CategoryIdRole  // appended: stable numeric roles for existing callers
    };
    Q_ENUM(Roles)

    explicit PackageModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    int count() const { return m_view.size(); }
    int totalCount() const { return m_entries.size(); }
    quint64 totalInstalledBytes() const;

    void resetFrom(QVector<PackageEntry> entries);
    Q_INVOKABLE void setFilter(const QString &text);
    Q_INVOKABLE void setCategory(const QString &categoryId);
    Q_INVOKABLE void sortBy(int role, bool ascending);
    Q_INVOKABLE QVariantMap get(int row) const;

    // Ordered [{id, count, bytes}] for every category present in the data.
    // Unfiltered by category/search — it feeds the category chip row.
    Q_INVOKABLE QVariantList categorySummary() const;

    // Maps a raw dpkg section ("universe/web", "gnome", "", ...) to a
    // stable category id ("internet", "desktop", "other", ...).
    static QString categoryIdForSection(const QString &section);

signals:
    void countChanged();

private:
    void applyView();

    QVector<PackageEntry> m_entries;
    QVector<int> m_view;
    QString m_filter;
    QString m_category;   // "" or "all" = every category
    int m_sortRole = SizeRole;
    bool m_sortAscending = false;
};
