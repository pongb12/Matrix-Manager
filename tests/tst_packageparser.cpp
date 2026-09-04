/*
 * tst_packageparser.cpp — unit tests for dpkg-query output parsing
 * (MM-110: package parsing).
 */
#include <QtTest>

#include "packages/PackageService.h"

class PackageParserTest : public QObject
{
    Q_OBJECT

private slots:
    void parsesInstalledPackages();
    void skipsNonInstalled();
    void skipsMalformedLines();
    void convertsInstalledSize();
    void validatesPackageNames();
    void handlesEmptyOutput();
};

void PackageParserTest::parsesInstalledPackages()
{
    const QString output = QStringLiteral(
        "firefox\tinstalled\t130.0-1\tamd64\t254000\tweb\tMozilla Firefox web browser\n"
        "nano\tinstalled\t7.2-1\tamd64\t550\teditors\tSmall, friendly text editor\n");

    const QVector<PackageEntry> entries = PackageService::parseDpkgQueryOutput(output);
    QCOMPARE(entries.size(), 2);
    QCOMPARE(entries.at(0).name, QStringLiteral("firefox"));
    QCOMPARE(entries.at(0).version, QStringLiteral("130.0-1"));
    QCOMPARE(entries.at(0).architecture, QStringLiteral("amd64"));
    QCOMPARE(entries.at(0).section, QStringLiteral("web"));
    QCOMPARE(entries.at(0).summary,
             QStringLiteral("Mozilla Firefox web browser"));
    QCOMPARE(entries.at(1).name, QStringLiteral("nano"));
}

void PackageParserTest::skipsNonInstalled()
{
    const QString output = QStringLiteral(
        "oldpkg\tconfig-files\t1.0\tamd64\t100\tutils\tOld package\n"
        "removed\tnot-installed\t\tamd64\t\tutils\tNever installed\n"
        "kept\tinstalled\t2.0\tall\t42\tutils\tKept package\n");

    const QVector<PackageEntry> entries = PackageService::parseDpkgQueryOutput(output);
    QCOMPARE(entries.size(), 1);
    QCOMPARE(entries.at(0).name, QStringLiteral("kept"));
}

void PackageParserTest::skipsMalformedLines()
{
    const QString output = QStringLiteral(
        "not-enough-fields\tinstalled\n"
        "\t\t\t\t\t\t\n"
        "ok\tinstalled\t1.0\tall\t10\tutils\tFine\n");

    const QVector<PackageEntry> entries = PackageService::parseDpkgQueryOutput(output);
    QCOMPARE(entries.size(), 1);
    QCOMPARE(entries.at(0).name, QStringLiteral("ok"));
}

void PackageParserTest::convertsInstalledSize()
{
    // Installed-Size is reported in KiB by dpkg.
    const QString output = QStringLiteral(
        "bigpkg\tinstalled\t1.0\tamd64\t2048\tutils\tBig package\n"
        "nopkg\tinstalled\t1.0\tamd64\t\tutils\tNo size field\n");

    const QVector<PackageEntry> entries = PackageService::parseDpkgQueryOutput(output);
    QCOMPARE(entries.at(0).installedSizeBytes, 2048ull * 1024ull);
    QCOMPARE(entries.at(1).installedSizeBytes, 0ull); // missing size is safe
}

void PackageParserTest::validatesPackageNames()
{
    QVERIFY(PackageService::isValidPackageName(QStringLiteral("firefox")));
    QVERIFY(PackageService::isValidPackageName(QStringLiteral("libqt6core6t64")));
    QVERIFY(PackageService::isValidPackageName(QStringLiteral("python3-minimal")));
    QVERIFY(PackageService::isValidPackageName(QStringLiteral("g++")));

    // Injection attempts and malformed names must be rejected.
    QVERIFY(!PackageService::isValidPackageName(QStringLiteral("pkg; rm -rf /")));
    QVERIFY(!PackageService::isValidPackageName(QStringLiteral("pkg && evil")));
    QVERIFY(!PackageService::isValidPackageName(QStringLiteral("$(dangerous)")));
    QVERIFY(!PackageService::isValidPackageName(QStringLiteral("pkg name with spaces")));
    QVERIFY(!PackageService::isValidPackageName(QStringLiteral("-leading-dash")));
    QVERIFY(!PackageService::isValidPackageName(QStringLiteral("UPPERCASE")));
    QVERIFY(!PackageService::isValidPackageName(QString()));
}

void PackageParserTest::handlesEmptyOutput()
{
    QVERIFY(PackageService::parseDpkgQueryOutput(QString()).isEmpty());
    QVERIFY(PackageService::parseDpkgQueryOutput(QStringLiteral("\n\n")).isEmpty());
}

QTEST_MAIN(PackageParserTest)
#include "tst_packageparser.moc"
