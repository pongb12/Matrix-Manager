/*
 * LargeFileService.h — large file detection and safe file actions (MM-030).
 *
 * - asynchronous scan of a chosen root with a configurable size threshold
 * - threshold default 500 MB, options 100 MB / 500 MB / 1 GB / 5 GB
 * - the page/service never deletes files silently: moving to trash happens
 *   only on explicit user action after confirmation in the UI
 */
#pragma once

#include <QAbstractListModel>
#include <QDateTime>
#include <QObject>
#include <QPointer>
#include <QVariantMap>
#include <QVector>
#include <atomic>

class QThread;

struct LargeFileEntry
{
    QString name;
    QString path;
    quint64 size = 0;
    QDateTime modified;
    QString type;      // upper-case suffix ("ISO", "MP4") or "FILE"
    bool hidden = false;
};

class LargeFileModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(quint64 totalBytes READ totalBytes NOTIFY countChanged)
    Q_PROPERTY(bool isEmpty READ isEmpty NOTIFY countChanged)

public:
    enum Roles
    {
        NameRole = Qt::UserRole + 1,
        PathRole,
        SizeRole,
        ModifiedRole,
        TypeRole,
        HiddenRole
    };
    Q_ENUM(Roles)

    explicit LargeFileModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    int count() const { return m_entries.size(); }
    quint64 totalBytes() const;
    bool isEmpty() const { return m_entries.isEmpty(); }

    void setEntries(QVector<LargeFileEntry> entries);
    Q_INVOKABLE void sortBy(int role, bool ascending);
    Q_INVOKABLE void setFilter(const QString &text);
    Q_INVOKABLE bool removePath(const QString &path);
    Q_INVOKABLE QVariantMap get(int row) const;

signals:
    void countChanged();

private:
    void applyView();

    QVector<LargeFileEntry> m_entries;   // full result set
    QVector<int> m_view;                 // visible indices after filter/sort
    QString m_filter;
    int m_sortRole = SizeRole;
    bool m_sortAscending = false;
};

class LargeFileService : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool running READ running NOTIFY runningChanged)
    Q_PROPERTY(quint64 filesSeen READ filesSeen NOTIFY progressChanged)
    Q_PROPERTY(LargeFileModel *model READ model CONSTANT)

public:
    static LargeFileService *instance();

    Q_INVOKABLE void start(const QString &rootPath);
    Q_INVOKABLE void cancel();

    bool running() const { return m_running; }
    quint64 filesSeen() const { return m_filesSeen; }
    LargeFileModel *model() const { return m_model; }

    // File actions available from the results list.
    Q_INVOKABLE static bool openFile(const QString &path);
    Q_INVOKABLE static bool showInFolder(const QString &path);
    Q_INVOKABLE static bool moveToTrash(const QString &path);

signals:
    void runningChanged();
    void progressChanged(quint64 filesSeen);
    void finished(const QString &rootPath, quint64 thresholdBytes,
                  const QVariantMap &summary);
    void failed(const QString &rootPath, const QString &message);

private:
    explicit LargeFileService(QObject *parent = nullptr);
    void runScan(const QString &rootPath, quint64 threshold);

    QPointer<QThread> m_thread;
    std::atomic_bool m_cancel{false};
    std::atomic_bool m_running{false};
    std::atomic<quint64> m_filesSeen{0};
    LargeFileModel *m_model = nullptr;
};
