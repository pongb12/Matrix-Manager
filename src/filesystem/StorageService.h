/*
 * StorageService.h — mounted volume information (MM-020).
 *
 * Uses QStorageInfo to enumerate real storage volumes, filtering out
 * pseudo filesystems (proc, sysfs, snap squashfs loops, ...). Data is read
 * on demand only; nothing is scanned at startup.
 */
#pragma once

#include <QObject>
#include <QVariantMap>

class StorageService : public QObject
{
    Q_OBJECT

public:
    static StorageService *instance();

    // QVariantMap fields per volume:
    //   mountPoint, device, fileSystem, totalBytes, usedBytes, freeBytes,
    //   usagePercent (0-100 int), isRoot (bool)
    Q_INVOKABLE QVariantList volumes() const;

    // Convenience: the volume containing the user's home directory.
    Q_INVOKABLE QVariantMap homeVolume() const;

    Q_INVOKABLE static QString homePath();

private:
    explicit StorageService(QObject *parent = nullptr);

    static bool isPseudoFilesystem(const QString &fstype);
};
