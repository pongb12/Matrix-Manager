/*
 * TranslationService.h — UI language handling (Vietnamese default).
 *
 * The interface ships with Vietnamese translations and English source
 * strings. The selected language is persisted through SettingsService;
 * this service installs/removes the QTranslator and keeps the default
 * QLocale in sync so number formatting follows the language too.
 *
 * The QML engine must be retranslated when the language changes; main.cpp
 * connects languageChanged() to QQmlApplicationEngine::retranslate().
 */
#pragma once

#include <QObject>
#include <QPointer>
#include <QTranslator>

class SettingsService;

class TranslationService : public QObject
{
    Q_OBJECT
    // Current UI language code: "vi" (default) or "en".
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY languageChanged)

public:
    static TranslationService *instance();

    QString language() const { return m_language; }
    void setLanguage(const QString &code);

    // Apply the language stored in SettingsService. Call once at startup,
    // before the QML engine loads, so the first frame is already translated.
    void applyStartupLanguage();

signals:
    void languageChanged();

private:
    explicit TranslationService(QObject *parent = nullptr);
    void installTranslator(const QString &code);

    QString m_language = QStringLiteral("vi");
    QPointer<QTranslator> m_translator;
};
