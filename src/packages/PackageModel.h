/*
 * PackageModel.h — data model for installed .deb packages (MM-041).
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
        SectionRole
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
    Q_INVOKABLE void sortBy(int role, bool ascending);
    Q_INVOKABLE QVariantMap get(int row) const;

signals:
    void countChanged();

private:
    void applyView();

    QVector<PackageEntry> m_entries;
    QVector<int> m_view;
    QString m_filter;
    int m_sortRole = SizeRole;
    bool m_sortAscending = false;
};
