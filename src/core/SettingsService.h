/*
 * SettingsService.h — persistent, minimal user settings (DOC.md rule 29).
 *
 * Only settings with real user value are persisted:
 *   - theme preference (system / light / dark)
 *   - default large-file threshold
 *   - confirmation preference for destructive operations
 *   - filesystem scan boundary options (follow symlinks is OFF by default)
 *
 * No filesystem maps, no usage data, no telemetry is ever persisted.
 */
#pragma once

#include <QObject>
#include <QSettings>
#include <QString>

class SettingsService : public QObject
{
    Q_OBJECT
    // 0 = follow system, 1 = light, 2 = dark
    Q_PROPERTY(int theme READ theme WRITE setTheme NOTIFY themeChanged)
    // Resolved theme actually used by the UI: 1 = light, 2 = dark
    Q_PROPERTY(int effectiveTheme READ effectiveTheme NOTIFY effectiveThemeChanged)
    Q_PROPERTY(quint64 largeFileThresholdBytes READ largeFileThresholdBytes
               WRITE setLargeFileThresholdBytes NOTIFY largeFileThresholdChanged)
    Q_PROPERTY(bool confirmDestructive READ confirmDestructive
               WRITE setConfirmDestructive NOTIFY confirmDestructiveChanged)
    Q_PROPERTY(bool followSymlinks READ followSymlinks
               WRITE setFollowSymlinks NOTIFY followSymlinksChanged)
    Q_PROPERTY(bool crossFilesystems READ crossFilesystems
               WRITE setCrossFilesystems NOTIFY crossFilesystemsChanged)
    // UI language code: "vi" (default) or "en"
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY languageChanged)

public:
    static SettingsService *instance();

    int theme() const { return m_theme; }
    void setTheme(int theme);

    int effectiveTheme() const;

    quint64 largeFileThresholdBytes() const { return m_largeFileThresholdBytes; }
    void setLargeFileThresholdBytes(quint64 bytes);

    bool confirmDestructive() const { return m_confirmDestructive; }
    void setConfirmDestructive(bool value);

    bool followSymlinks() const { return m_followSymlinks; }
    void setFollowSymlinks(bool value);

    bool crossFilesystems() const { return m_crossFilesystems; }
    void setCrossFilesystems(bool value);

    QString language() const { return m_language; }
    void setLanguage(const QString &code);

    // Re-evaluate the system color scheme (called when the desktop theme
    // changes at runtime, on Qt >= 6.5; on older Qt this happens at startup).
    Q_INVOKABLE void refreshEffectiveTheme();

signals:
    void themeChanged();
    void effectiveThemeChanged();
    void largeFileThresholdChanged();
    void confirmDestructiveChanged();
    void followSymlinksChanged();
    void crossFilesystemsChanged();
    void languageChanged();

private:
    explicit SettingsService(QObject *parent = nullptr);
    static bool systemPrefersDark();

    QSettings m_settings;
    int m_theme = 0;
    quint64 m_largeFileThresholdBytes = 500ull * 1024ull * 1024ull; // 500 MiB
    bool m_confirmDestructive = true;
    bool m_followSymlinks = false;
    bool m_crossFilesystems = false;
    QString m_language = QStringLiteral("vi");
};
