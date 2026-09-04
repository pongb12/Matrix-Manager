#include "LargeFileService.h"
#include "FileWalker.h"
#include "core/SettingsService.h"
#include "core/ActivityLog.h"
#include "core/SizeUtils.h"

#include <QDesktopServices>
#include <QDir>
#include <QThread>
#include <QUrl>

LargeFileModel::LargeFileModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int LargeFileModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_view.size();
}

QVariant LargeFileModel::data(const QModelIndex &index, int role) const
{
    if (index.row() < 0 || index.row() >= m_view.size())
        return {};
    const LargeFileEntry &entry = m_entries.at(m_view.at(index.row()));

    switch (role) {
    case NameRole:
        return entry.name;
    case PathRole:
        return entry.path;
    case SizeRole:
        return entry.size;
    case ModifiedRole:
        return entry.modified;
    case TypeRole:
        return entry.type;
    case HiddenRole:
        return entry.hidden;
    default:
        return {};
    }
}

QHash<int, QByteArray> LargeFileModel::roleNames() const
{
    return {
        { NameRole, "name" },
        { PathRole, "path" },
        { SizeRole, "size" },
        { ModifiedRole, "modified" },
        { TypeRole, "fileType" },
        { HiddenRole, "hidden" }
    };
}

quint64 LargeFileModel::totalBytes() const
{
    quint64 total = 0;
    for (const LargeFileEntry &entry : m_entries)
        total += entry.size;
    return total;
}

void LargeFileModel::setEntries(QVector<LargeFileEntry> entries)
{
    beginResetModel();
    m_entries = std::move(entries);
    applyView();
    endResetModel();
    emit countChanged();
}

void LargeFileModel::sortBy(int role, bool ascending)
{
    m_sortRole = role;
    m_sortAscending = ascending;
    beginResetModel();
    applyView();
    endResetModel();
}

void LargeFileModel::setFilter(const QString &text)
{
    if (text == m_filter)
        return;
    m_filter = text;
    beginResetModel();
    applyView();
    endResetModel();
}

void LargeFileModel::applyView()
{
    m_view.clear();
    m_view.reserve(m_entries.size());
    for (int i = 0; i < m_entries.size(); ++i) {
        if (m_filter.isEmpty()
            || m_entries.at(i).name.contains(m_filter, Qt::CaseInsensitive)
            || m_entries.at(i).path.contains(m_filter, Qt::CaseInsensitive))
            m_view.append(i);
    }

    std::stable_sort(m_view.begin(), m_view.end(),
                     [this](int a, int b) {
        const LargeFileEntry &ea = m_entries.at(a);
        const LargeFileEntry &eb = m_entries.at(b);
        int cmp = 0;
        switch (m_sortRole) {
        case NameRole:
            cmp = QString::compare(ea.name.toLower(), eb.name.toLower());
            break;
        case PathRole:
            cmp = QString::compare(ea.path.toLower(), eb.path.toLower());
            break;
        case ModifiedRole:
            cmp = ea.modified < eb.modified ? -1 : (ea.modified == eb.modified ? 0 : 1);
            break;
        case TypeRole:
            cmp = QString::compare(ea.type, eb.type);
            break;
        case SizeRole:
        default:
            cmp = ea.size < eb.size ? -1 : (ea.size == eb.size ? 0 : 1);
            break;
        }
        return m_sortAscending ? cmp < 0 : cmp > 0;
    });
}

bool LargeFileModel::removePath(const QString &path)
{
    for (int i = 0; i < m_entries.size(); ++i) {
        if (m_entries.at(i).path != path)
            continue;
        const int viewRow = m_view.indexOf(i);
        if (viewRow >= 0) {
            beginRemoveRows(QModelIndex(), viewRow, viewRow);
            m_entries.removeAt(i);
            applyView();
            endRemoveRows();
        } else {
            beginResetModel();
            m_entries.removeAt(i);
            applyView();
            endResetModel();
        }
        emit countChanged();
        return true;
    }
    return false;
}

QVariantMap LargeFileModel::get(int row) const
{
    QVariantMap map;
    if (row < 0 || row >= m_view.size())
        return map;
    const LargeFileEntry &entry = m_entries.at(m_view.at(row));
    map.insert(QStringLiteral("name"), entry.name);
    map.insert(QStringLiteral("path"), entry.path);
    map.insert(QStringLiteral("size"), entry.size);
    map.insert(QStringLiteral("modified"), entry.modified);
    map.insert(QStringLiteral("fileType"), entry.type);
    map.insert(QStringLiteral("hidden"), entry.hidden);
    return map;
}

// ---------------------------------------------------------------------------

LargeFileService *LargeFileService::instance()
{
    static LargeFileService service;
    return &service;
}

LargeFileService::LargeFileService(QObject *parent)
    : QObject(parent)
    , m_model(new LargeFileModel(this))
{
}

void LargeFileService::start(const QString &rootPath)
{
    if (m_running) {
        qWarning("LargeFileService: scan already in progress");
        return;
    }
    if (rootPath.isEmpty())
        return;

    const QDir dir(rootPath);
    if (!dir.exists() || !dir.isReadable()) {
        emit failed(rootPath,
                    QStringLiteral("Directory does not exist or is not readable"));
        return;
    }

    m_cancel = false;
    m_filesSeen = 0;
    m_running = true;
    emit runningChanged();

    const quint64 threshold = SettingsService::instance()->largeFileThresholdBytes();
    auto *thread = QThread::create([this, rootPath, threshold] {
        runScan(rootPath, threshold);
    });
    connect(thread, &QThread::finished, thread, &QObject::deleteLater);
    m_thread = thread;
    thread->start();
}

void LargeFileService::cancel()
{
    m_cancel = true;
}

void LargeFileService::runScan(const QString &rootPath, quint64 threshold)
{
    const QString normalized = QDir(rootPath).absolutePath();
    QVector<LargeFileEntry> entries;
    quint64 bytesSeen = 0;

    FileWalker walker;
    walker.setFollowSymlinks(SettingsService::instance()->followSymlinks());
    walker.setCrossFilesystems(SettingsService::instance()->crossFilesystems());

    walker.walk(normalized, [this, &walker, &entries, &bytesSeen, threshold]
                            (const QFileInfo &info, bool isSymLink) {
        if (m_cancel)
            return;

        bytesSeen += isSymLink ? 0 : static_cast<quint64>(info.size());

        const quint64 size = static_cast<quint64>(info.size());
        if (isSymLink || size < threshold)
            return;

        LargeFileEntry entry;
        entry.name = info.fileName();
        entry.path = info.absoluteFilePath();
        entry.size = size;
        entry.modified = info.lastModified();
        const QString suffix = info.suffix();
        entry.type = suffix.isEmpty() ? QStringLiteral("FILE")
                                      : suffix.toUpper();
        entry.hidden = entry.name.startsWith(QLatin1Char('.'));
        entries.append(entry);

        if (walker.filesSeen() % 500 == 0) {
            m_filesSeen.store(walker.filesSeen());
            emit progressChanged(m_filesSeen.load());
        }
    });

    m_filesSeen.store(walker.filesSeen());

    QVariantMap summary;
    summary.insert(QStringLiteral("cancelled"), walker.wasCancelled());
    summary.insert(QStringLiteral("filesFound"), static_cast<quint64>(entries.size()));
    summary.insert(QStringLiteral("totalBytes"), bytesSeen);
    summary.insert(QStringLiteral("errorCount"),
                   static_cast<quint64>(walker.errors().size()));

    m_model->setEntries(std::move(entries));

    m_running = false;
    emit runningChanged();

    if (walker.wasCancelled())
        emit finished(normalized, threshold, summary);
    else if (walker.errors().size() > 0 && walker.filesSeen() == 0 && entries.isEmpty())
        emit failed(normalized, walker.errors().first());
    else
        emit finished(normalized, threshold, summary);
}

bool LargeFileService::openFile(const QString &path)
{
    return QDesktopServices::openUrl(QUrl::fromLocalFile(path));
}

bool LargeFileService::showInFolder(const QString &path)
{
    const QFileInfo info(path);
    return QDesktopServices::openUrl(QUrl::fromLocalFile(info.absolutePath()));
}

bool LargeFileService::moveToTrash(const QString &path)
{
    QFileInfo info(path);
    const QString name = info.fileName();
    const quint64 size = static_cast<quint64>(info.size());

    QString target;
    if (!QFile::moveToTrash(path, &target)) {
        qWarning("Could not move %s to trash", qPrintable(path));
        return false;
    }

    ActivityLog::instance()->add(
        QStringLiteral("Moved to trash: %1").arg(name),
        QStringLiteral("%1 — %2").arg(path, SizeUtils::formatBytes(size)));
    return true;
}
