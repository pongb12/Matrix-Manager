#include "SystemInfo.h"
#include "SizeUtils.h"

#include <QFile>
#include <QFontDatabase>
#include <QGuiApplication>
#include <QTextStream>
#include <QSysInfo>

SystemInfo::SystemInfo(QObject *parent)
    : QObject(parent)
    , m_appVersion(QString::fromLatin1(MM_APP_VERSION))
    , m_osName(detectOsName())
    , m_monoFontFamily(QFontDatabase::systemFont(QFontDatabase::FixedFont).family())
{
}

QString SystemInfo::detectOsName()
{
    QFile file(QStringLiteral("/etc/os-release"));
    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream stream(&file);
        while (!stream.atEnd()) {
            const QString line = stream.readLine();
            if (line.startsWith(QLatin1String("PRETTY_NAME="))) {
                QString value = line.mid(QString::fromLatin1("PRETTY_NAME=").size());
                value.remove(QLatin1Char('"'));
                if (!value.isEmpty())
                    return value;
            }
        }
    }
    return QStringLiteral("Linux");
}

QString SystemInfo::architecture() const
{
    return QSysInfo::currentCpuArchitecture();
}

QString SystemInfo::supportedPlatforms()
{
    return QStringLiteral("Linux Mint, Ubuntu, Debian (amd64/arm64)");
}

QString SystemInfo::formatBytes(quint64 bytes)
{
    return SizeUtils::formatBytes(bytes);
}

QString SystemInfo::formatDateTime(const QDateTime &timestamp)
{
    return timestamp.toLocalTime().toString(QStringLiteral("yyyy-MM-dd HH:mm"));
}

QString SystemInfo::formatCount(quint64 value)
{
    return QLocale().toString(qlonglong(value));
}
