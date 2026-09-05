/*
 * Matrix Manager — application entry point.
 *
 * Matrix Manager is a local-first Linux desktop utility (see DOC.md).
 * Startup performs no filesystem scans, no package queries and no network
 * access: only the UI and lightweight initial state are loaded (MM-100).
 */
#include "core/ActivityLog.h"
#include "core/SettingsService.h"
#include "core/SystemInfo.h"
#include "core/TranslationService.h"
#include "filesystem/LargeFileService.h"
#include "filesystem/StorageService.h"
#include "filesystem/DirectoryScanner.h"
#include "filesystem/DuplicateScanner.h"
#include "filesystem/FileSearcher.h"
#include "packages/PackageService.h"
#include "cleanup/CleanupService.h"

#include <QFile>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QTimer>
#include <QUrl>
#include <qqml.h>

#ifdef MM_QA_SUPPORT
// Minimal file logger for automated UI checks. Only registered when the
// MM_QA environment is active; normal users never see this object.
class QaLog : public QObject
{
    Q_OBJECT
public:
    Q_INVOKABLE void log(const QString &line)
    {
        QFile f(QStringLiteral("/tmp/mm_qa.log"));
        if (f.open(QIODevice::Append))
            f.write(line.toUtf8() + '\n');
    }
};
#endif

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QGuiApplication::setOrganizationName(QStringLiteral("MatrixManager"));
    QGuiApplication::setApplicationName(QStringLiteral("MatrixManager"));
    QGuiApplication::setApplicationVersion(QStringLiteral(MM_APP_VERSION));

    // Deterministic styling across distributions (Basic = flat, stylable).
    QQuickStyle::setStyle(QStringLiteral("Basic"));

    // Register C++ services under the MatrixManager.Core namespace.
    // Instances are owned by the application object and live for the
    // entire session — they are singletons by design, not caches.
    qmlRegisterSingletonInstance("MatrixManager.Core", 1, 0,
                                 "SettingsService", SettingsService::instance());
    qmlRegisterSingletonInstance("MatrixManager.Core", 1, 0,
                                 "StorageService", StorageService::instance());
    qmlRegisterSingletonInstance("MatrixManager.Core", 1, 0,
                                 "PackageService", PackageService::instance());
    qmlRegisterSingletonInstance("MatrixManager.Core", 1, 0,
                                 "CleanupService", CleanupService::instance());
    qmlRegisterSingletonInstance("MatrixManager.Core", 1, 0,
                                 "LargeFileService", LargeFileService::instance());
    qmlRegisterSingletonInstance("MatrixManager.Core", 1, 0,
                                 "ActivityLog", ActivityLog::instance());
    qmlRegisterSingletonInstance("MatrixManager.Core", 1, 0,
                                 "SystemInfo", new SystemInfo(&app));
    qmlRegisterSingletonInstance("MatrixManager.Core", 1, 0,
                                 "TranslationService", TranslationService::instance());
    qmlRegisterType<DirectoryScanner>("MatrixManager.Core", 1, 0,
                                      "DirectoryScanner");
    qmlRegisterType<DuplicateScanner>("MatrixManager.Core", 1, 0,
                                      "DuplicateScanner");
    qmlRegisterType<FileSearcher>("MatrixManager.Core", 1, 0,
                                  "FileSearcher");

    QQmlApplicationEngine engine;
    // QML modules share RESOURCE_PREFIX /qml (see CMakeLists.txt).
    engine.addImportPath(QStringLiteral("qrc:/qml"));

    // Vietnamese is the default interface language (MM-1xx, user request).
    // Install the translator before the engine loads so the first frame is
    // already in the selected language; live switches retranslate below.
    TranslationService::instance()->applyStartupLanguage();
    QObject::connect(TranslationService::instance(), &TranslationService::languageChanged,
                     &engine, &QQmlApplicationEngine::retranslate,
                     Qt::QueuedConnection);

    // QA support: MM_QA_SCAN=<path> auto-starts a storage scan so that
    // automated UI checks can exercise the results table. Unset normally.
    const QString qaScan = qEnvironmentVariable("MM_QA_SCAN");
    const QString qaGuide = qEnvironmentVariable("MM_QA_GUIDE");
#ifdef MM_QA_SUPPORT
    if (!qaScan.isEmpty()) {
        engine.rootContext()->setContextProperty(QStringLiteral("qaScanPath"), qaScan);
        engine.rootContext()->setContextProperty(QStringLiteral("qaLog"), new QaLog());
        QFile::remove(QStringLiteral("/tmp/mm_qa.log"));
    }
    const QString qaDup = qEnvironmentVariable("MM_QA_DUP_SCAN");
    if (!qaDup.isEmpty())
        engine.rootContext()->setContextProperty(QStringLiteral("qaDupScanPath"), qaDup);
    const QString qaMode = qEnvironmentVariable("MM_QA_STORAGE_MODE");
    if (!qaMode.isEmpty())
        engine.rootContext()->setContextProperty(QStringLiteral("qaStorageMode"), qaMode.toInt());
    const QString qaSearch = qEnvironmentVariable("MM_QA_SEARCH_NAME");
    if (!qaSearch.isEmpty())
        engine.rootContext()->setContextProperty(QStringLiteral("qaSearchName"), qaSearch);
    if (!qaGuide.isEmpty())
        engine.rootContext()->setContextProperty(QStringLiteral("qaGuideStep"), qaGuide);
#else
    Q_UNUSED(qaScan);
    Q_UNUSED(qaGuide);
#endif

    const QUrl url(QStringLiteral("qrc:/qml/MatrixManager/Main.qml"));
    // objectCreated works on Qt 6.0+; objectCreationFailed would need 6.5+.
    // A null root object means QML creation failed (syntax error, missing
    // module, ...) — quit with a non-zero status instead of a blank window.
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [url](QObject *obj, const QUrl &objUrl) {
            if (objUrl == url && obj == nullptr)
                QCoreApplication::exit(EXIT_FAILURE);
        },
        Qt::QueuedConnection);
    engine.load(url);

    // QA support: MM_QA_PAGES="0,1,..." + MM_QA_OUT=<dir> capture a PNG of
    // each listed page for automated UI inspection, then quit.
    const QString qaPages = qEnvironmentVariable("MM_QA_PAGES");
    const QString qaOut = qEnvironmentVariable("MM_QA_OUT");
    if (!qaPages.isEmpty() && !qaOut.isEmpty()) {
        if (auto *win = qobject_cast<QQuickWindow *>(engine.rootObjects().value(0))) {
            int delay = 600;
            const QStringList indexes = qaPages.split(',');
            const bool guideActive = !qaGuide.isEmpty();
            for (const QString &s : indexes) {
                bool ok = false;
                const int idx = s.toInt(&ok);
                if (!ok)
                    continue;
                // With the guided tour active it navigates by itself; an
                // unconditional qaShowPage here would race its prepare().
                if (!guideActive) {
                    QTimer::singleShot(delay, win, [win, idx]() {
                        QMetaObject::invokeMethod(win, "qaShowPage", Q_ARG(QVariant, idx));
                    });
                }
                delay += 900;
                const QString out = qaOut + QStringLiteral("/page%1.png").arg(idx);
                QTimer::singleShot(delay, win, [win, out]() {
                    const QImage img = win->grabWindow();
                    const bool ok = !img.isNull() && img.save(out);
                    qInfo() << "[qa] grab" << out << "size" << img.size() << "ok" << ok;
                });
                delay += 200;
            }
            QTimer::singleShot(delay + 300, win, &QCoreApplication::quit);
        }
    }

    return app.exec();
}

#ifdef MM_QA_SUPPORT
#include "main.moc"
#endif
