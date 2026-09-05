/*
 * tst_cleanuprules.cpp — unit tests for the cleanup rule registry
 * (MM-110: cleanup rule evaluation).
 *
 * Safety contract checks: every rule has an explicit identity, honest
 * risk level and description; guard helpers reject unsafe paths.
 */
#include <QtTest>

#include "cleanup/CleanupService.h"

#include <QCoreApplication>
#include <QDir>
#include <QSet>

class CleanupRulesTest : public QObject
{
    Q_OBJECT

private slots:
    void knownRulesExist();
    void ruleFieldsAreComplete();
    void riskLevelsAreValid();
    void guardRejectsOutsidePaths();
    void guardAcceptsInsidePaths();
};

void CleanupRulesTest::knownRulesExist()
{
    CleanupService *service = CleanupService::instance();
    const QVariantList rules = service->rules();

    QSet<QString> ids;
    for (const QVariant &v : rules)
        ids.insert(v.toMap().value(QStringLiteral("id")).toString());

    QVERIFY(ids.contains(QStringLiteral("user-trash")));
    QVERIFY(ids.contains(QStringLiteral("apt-cache")));
    QVERIFY(ids.contains(QStringLiteral("thumbnail-cache")));
}

void CleanupRulesTest::ruleFieldsAreComplete()
{
    const QVariantList rules = CleanupService::instance()->rules();
    QVERIFY(rules.size() >= 3);

    for (const QVariant &v : rules) {
        const QVariantMap rule = v.toMap();
        const QString id = rule.value(QStringLiteral("id")).toString();

        QVERIFY2(!rule.value(QStringLiteral("name")).toString().isEmpty(),
                 qPrintable(QStringLiteral("%1: name empty").arg(id)));
        QVERIFY2(!rule.value(QStringLiteral("description")).toString().isEmpty(),
                 qPrintable(QStringLiteral("%1: description empty").arg(id)));
        QVERIFY2(!rule.value(QStringLiteral("consequence")).toString().isEmpty(),
                 qPrintable(QStringLiteral("%1: consequence empty").arg(id)));
        QVERIFY2(!rule.value(QStringLiteral("targets")).toStringList().isEmpty(),
                 qPrintable(QStringLiteral("%1: targets empty").arg(id)));
    }
}

void CleanupRulesTest::riskLevelsAreValid()
{
    const QVariantList rules = CleanupService::instance()->rules();
    for (const QVariant &v : rules) {
        const QVariantMap rule = v.toMap();
        const int level = rule.value(QStringLiteral("riskLevel")).toInt();
        QVERIFY(level >= 0 && level <= 2);

        // The rules shipped in the MVP must be low/medium risk; a HIGH
        // risk rule would contradict the documented safety philosophy.
        QVERIFY2(level < 2,
                 qPrintable(QStringLiteral("%1 must not be HIGH risk")
                                .arg(rule.value(QStringLiteral("id")).toString())));
    }
}

void CleanupRulesTest::guardRejectsOutsidePaths()
{
    const QString trash = CleanupService::trashRootPath();
    QVERIFY(!CleanupService::isSafeSubPath(trash, QStringLiteral("/etc/passwd")));
    QVERIFY(!CleanupService::isSafeSubPath(trash, QStringLiteral("/usr/bin")));
    QVERIFY(!CleanupService::isSafeSubPath(trash, QDir::homePath()));
    QVERIFY(!CleanupService::isSafeSubPath(trash, QString()));

    // Regression (first caught on a fresh CI runner, ubuntu-24.04):
    // when the root does not exist its canonical path is empty and
    // startsWith("") accepted ANY existing path. A missing root must
    // close the guard, not open it.
    const QString gone = QDir::tempPath()
        + QStringLiteral("/matrix-manager-guard-%1")
              .arg(QCoreApplication::applicationPid());
    QVERIFY(!CleanupService::isSafeSubPath(gone, QStringLiteral("/etc/passwd")));
    QVERIFY(!CleanupService::isSafeSubPath(gone, QDir::homePath()));
    QVERIFY(!CleanupService::isSafeSubPath(gone,
                                           gone + QStringLiteral("/entry")));
}

void CleanupRulesTest::guardAcceptsInsidePaths()
{
    const QString trash = CleanupService::trashRootPath();
    QDir().mkpath(trash + QStringLiteral("/files/testentry"));
    QVERIFY(CleanupService::isSafeSubPath(
        trash, trash + QStringLiteral("/files/testentry")));
    QVERIFY(CleanupService::isSafeSubPath(trash, trash));
    QDir(trash + QStringLiteral("/files")).removeRecursively();
    QDir(trash + QStringLiteral("/info")).removeRecursively();
}

QTEST_MAIN(CleanupRulesTest)
#include "tst_cleanuprules.moc"
