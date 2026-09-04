#include "SettingsService.h"

#include <QGuiApplication>
#include <QPalette>
#include <QStyleHints>

SettingsService *SettingsService::instance()
{
    static SettingsService service;
    return &service;
}

SettingsService::SettingsService(QObject *parent)
    : QObject(parent)
{
    m_theme = m_settings.value(QStringLiteral("ui/theme"), 0).toInt();
    if (m_theme < 0 || m_theme > 2)
        m_theme = 0;

    const quint64 defaultThreshold = 500ull * 1024ull * 1024ull;
    m_largeFileThresholdBytes = m_settings
        .value(QStringLiteral("scanner/largeFileThresholdBytes"), defaultThreshold)
        .toULongLong();
    if (m_largeFileThresholdBytes == 0)
        m_largeFileThresholdBytes = defaultThreshold;

    m_confirmDestructive = m_settings
        .value(QStringLiteral("safety/confirmDestructive"), true).toBool();
    m_followSymlinks = m_settings
        .value(QStringLiteral("scanner/followSymlinks"), false).toBool();
    m_crossFilesystems = m_settings
        .value(QStringLiteral("scanner/crossFilesystems"), false).toBool();

    QString lang = m_settings.value(QStringLiteral("ui/language"),
                                    QStringLiteral("vi")).toString();
    if (lang != QLatin1String("vi") && lang != QLatin1String("en"))
        lang = QStringLiteral("vi");
    m_language = lang;

#if QT_VERSION >= QT_VERSION_CHECK(6, 5, 0)
    // Follow live desktop theme changes where Qt can report them.
    connect(QGuiApplication::styleHints(), &QStyleHints::colorSchemeChanged,
            this, &SettingsService::refreshEffectiveTheme);
#endif
}

bool SettingsService::systemPrefersDark()
{
#if QT_VERSION >= QT_VERSION_CHECK(6, 5, 0)
    return QGuiApplication::styleHints()->colorScheme() == Qt::ColorScheme::Dark;
#else
    // Qt 6.2-6.4 has no color scheme API; approximate via the platform
    // palette window colour lightness. This is a documented decision.
    const QPalette palette = QGuiApplication::palette();
    return palette.color(QPalette::Window).lightness() < 128;
#endif
}

int SettingsService::effectiveTheme() const
{
    if (m_theme == 1)
        return 1;
    if (m_theme == 2)
        return 2;
    return systemPrefersDark() ? 2 : 1;
}

void SettingsService::setTheme(int theme)
{
    if (theme < 0 || theme > 2 || theme == m_theme)
        return;
    m_theme = theme;
    m_settings.setValue(QStringLiteral("ui/theme"), m_theme);
    emit themeChanged();
    emit effectiveThemeChanged();
}

void SettingsService::setLargeFileThresholdBytes(quint64 bytes)
{
    if (bytes == 0 || bytes == m_largeFileThresholdBytes)
        return;
    m_largeFileThresholdBytes = bytes;
    m_settings.setValue(QStringLiteral("scanner/largeFileThresholdBytes"),
                        m_largeFileThresholdBytes);
    emit largeFileThresholdChanged();
}

void SettingsService::setConfirmDestructive(bool value)
{
    if (value == m_confirmDestructive)
        return;
    m_confirmDestructive = value;
    m_settings.setValue(QStringLiteral("safety/confirmDestructive"), value);
    emit confirmDestructiveChanged();
}

void SettingsService::setFollowSymlinks(bool value)
{
    if (value == m_followSymlinks)
        return;
    m_followSymlinks = value;
    m_settings.setValue(QStringLiteral("scanner/followSymlinks"), value);
    emit followSymlinksChanged();
}

void SettingsService::setCrossFilesystems(bool value)
{
    if (value == m_crossFilesystems)
        return;
    m_crossFilesystems = value;
    m_settings.setValue(QStringLiteral("scanner/crossFilesystems"), value);
    emit crossFilesystemsChanged();
}

void SettingsService::setLanguage(const QString &code)
{
    if ((code != QLatin1String("vi") && code != QLatin1String("en"))
            || code == m_language)
        return;
    m_language = code;
    m_settings.setValue(QStringLiteral("ui/language"), m_language);
    emit languageChanged();
}

void SettingsService::refreshEffectiveTheme()
{
    emit effectiveThemeChanged();
}
