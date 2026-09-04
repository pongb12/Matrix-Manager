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
#include "filesystem/LargeFileService.h"
#include "filesystem/StorageService.h"
#include "filesystem/DirectoryScanner.h"
#include "packages/PackageService.h"
#include "cleanup/CleanupService.h"

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QUrl>
#include <qqml.h>

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
    qmlRegisterType<DirectoryScanner>("MatrixManager.Core", 1, 0,
                                      "DirectoryScanner");

    QQmlApplicationEngine engine;
    // QML modules share RESOURCE_PREFIX /qml (see CMakeLists.txt).
    engine.addImportPath(QStringLiteral("qrc:/qml"));

    const QUrl url(QStringLiteral("qrc:/qml/MatrixManager/Main.qml"));
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(EXIT_FAILURE); },
        Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
