/*
 * SystemInfo.h — read-only application and platform information.
 *
 * Used by the About section of the Settings page (MM-071). Exposes only
 * truthful information; no fabricated metadata.
 */
#pragma once

#include <QDateTime>
#include <QObject>
#include <QString>

class SystemInfo : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString appVersion READ appVersion CONSTANT)
    Q_PROPERTY(QString qtVersion READ qtVersion CONSTANT)
    Q_PROPERTY(QString osName READ osName CONSTANT)
    Q_PROPERTY(QString architecture READ architecture CONSTANT)
    Q_PROPERTY(QString monoFontFamily READ monoFontFamily CONSTANT)

public:
    explicit SystemInfo(QObject *parent = nullptr);

    QString appVersion() const { return m_appVersion; }
    QString qtVersion() const { return QString::fromLatin1(qVersion()); }
    QString osName() const { return m_osName; }
    QString architecture() const;
    QString monoFontFamily() const { return m_monoFontFamily; }

    // Supported platform list, fixed by DOC.md rule 2.
    Q_INVOKABLE static QString supportedPlatforms();

    // Size formatting exposed to QML (single convention, DOC.md rule 7).
    Q_INVOKABLE static QString formatBytes(quint64 bytes);
    Q_INVOKABLE static QString formatDateTime(const QDateTime &timestamp);

private:
    static QString detectOsName();

    QString m_appVersion;
    QString m_osName;
    QString m_monoFontFamily;
};
