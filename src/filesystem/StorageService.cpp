#include "StorageService.h"

#include <QDir>
#include <QStorageInfo>
#include <algorithm>

StorageService *StorageService::instance()
{
    static StorageService service;
    return &service;
}

StorageService::StorageService(QObject *parent)
    : QObject(parent)
{
}

bool StorageService::isPseudoFilesystem(const QString &fstype)
{
    static const QSet<QString> pseudo = {
        QStringLiteral("proc"),        QStringLiteral("sysfs"),
        QStringLiteral("devtmpfs"),    QStringLiteral("devpts"),
        QStringLiteral("tmpfs"),       QStringLiteral("ramfs"),
        QStringLiteral("squashfs"),    QStringLiteral("overlay"),
        QStringLiteral("aufs"),        QStringLiteral("efivarfs"),
        QStringLiteral("cgroup"),      QStringLiteral("cgroup2"),
        QStringLiteral("securityfs"),  QStringLiteral("pstore"),
        QStringLiteral("debugfs"),     QStringLiteral("tracefs"),
        QStringLiteral("fusectl"),     QStringLiteral("configfs"),
        QStringLiteral("bpf"),         QStringLiteral("autofs"),
        QStringLiteral("mqueue"),      QStringLiteral("hugetlbfs"),
        QStringLiteral("binfmt_misc"), QStringLiteral("nsfs"),
        QStringLiteral("rpc_pipefs"),  QStringLiteral("rootfs"),
        QStringLiteral("fuse.gvfsd-fuse"), QStringLiteral("fuse.portal"),
        QStringLiteral("tracefs"),     QStringLiteral("binder"),
        QStringLiteral("procfs")
    };
    return pseudo.contains(fstype);
}

QVariantList StorageService::volumes() const
{
    QVariantList result;

    const QList<QStorageInfo> all = QStorageInfo::mountedVolumes();
    for (const QStorageInfo &volume : all) {
        if (!volume.isValid())
            continue; // read-only volumes are kept: they are still real storage
        if (isPseudoFilesystem(QString::fromLocal8Bit(volume.fileSystemType())))
            continue;
        if (volume.bytesTotal() <= 0)
            continue;

        QVariantMap map;
        map.insert(QStringLiteral("mountPoint"),
                   volume.rootPath());
        map.insert(QStringLiteral("device"),
                   QString::fromLocal8Bit(volume.device()));
        map.insert(QStringLiteral("fileSystem"),
                   QString::fromLocal8Bit(volume.fileSystemType()));
        const qint64 total = volume.bytesTotal();
        const qint64 free = volume.bytesFree();
        const qint64 used = total - free;
        map.insert(QStringLiteral("totalBytes"), static_cast<quint64>(total));
        map.insert(QStringLiteral("usedBytes"), static_cast<quint64>(used));
        map.insert(QStringLiteral("freeBytes"), static_cast<quint64>(free));
        map.insert(QStringLiteral("usagePercent"),
                   total > 0 ? qRound(100.0 * used / total) : 0);
        map.insert(QStringLiteral("isRoot"),
                   volume.rootPath() == QLatin1String("/"));
        result.append(map);
    }

    // Root volume first, then alphabetical by mount point.
    std::sort(result.begin(), result.end(),
              [](const QVariant &a, const QVariant &b) {
        const QVariantMap ma = a.toMap();
        const QVariantMap mb = b.toMap();
        const bool rootA = ma.value(QStringLiteral("isRoot")).toBool();
        const bool rootB = mb.value(QStringLiteral("isRoot")).toBool();
        if (rootA != rootB)
            return rootA;
        return ma.value(QStringLiteral("mountPoint")).toString()
             < mb.value(QStringLiteral("mountPoint")).toString();
    });

    return result;
}

QVariantMap StorageService::homeVolume() const
{
    QStorageInfo home(QDir::homePath());
    for (const QVariant &v : volumes()) {
        const QVariantMap map = v.toMap();
        if (map.value(QStringLiteral("mountPoint")).toString()
                == home.rootPath())
            return map;
    }
    return {};
}

QString StorageService::homePath()
{
    return QDir::homePath();
}
