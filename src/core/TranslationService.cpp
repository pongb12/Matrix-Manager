#include "TranslationService.h"

#include "SettingsService.h"

#include <QCoreApplication>
#include <QLocale>

TranslationService *TranslationService::instance()
{
    static TranslationService service;
    return &service;
}

TranslationService::TranslationService(QObject *parent)
    : QObject(parent)
{
    // SettingsService is the source of truth; follow external changes.
    connect(SettingsService::instance(), &SettingsService::languageChanged,
            this, [this]() {
        const QString code = SettingsService::instance()->language();
        if (code != m_language) {
            m_language = code;
            installTranslator(m_language);
        }
    });
}

void TranslationService::setLanguage(const QString &code)
{
    SettingsService::instance()->setLanguage(code);
}

void TranslationService::applyStartupLanguage()
{
    const QString code = SettingsService::instance()->language();
    if (code != m_language)
        m_language = code;
    installTranslator(m_language);
}

void TranslationService::installTranslator(const QString &code)
{
    if (m_translator) {
        QCoreApplication::removeTranslator(m_translator);
        m_translator->deleteLater();
        m_translator = nullptr;
    }

    if (code == QLatin1String("vi")) {
        auto *translator = new QTranslator(this);
        if (translator->load(QStringLiteral(":/translations/matrix-manager_vi.qm"))) {
            QCoreApplication::installTranslator(translator);
            m_translator = translator;
        } else {
            delete translator;
        }
        // Number and date formatting follows the language as well.
        QLocale::setDefault(QLocale(QLocale::Vietnamese, QLocale::Vietnam));
    } else {
        QLocale::setDefault(QLocale(QLocale::English, QLocale::UnitedStates));
    }

    emit languageChanged();
}
