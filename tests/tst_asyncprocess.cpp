/*
 * tst_asyncprocess.cpp — regression test for AsyncProcess output capture.
 *
 * Bug this locks down: AsyncProcess consumed output in the readyRead
 * handler but the finished signal only forwarded QProcess::readAll() —
 * the unread remainder. For large outputs (dpkg-query lists every
 * installed package) the pipe was drained before process exit, so
 * PackageService parsed an (almost) empty stream and the Applications
 * page showed zero packages. The fix accumulates every chunk and
 * delivers the complete output exactly once.
 */
#include <QtTest>

#include "platform/linux/ProcessRunner.h"

#include <QCoreApplication>
#include <QEventLoop>
#include <QTimer>

class AsyncProcessTest : public QObject
{
    Q_OBJECT

private slots:
    void largeOutputIsFullyCaptured();
    void failingProcessReportsExitCode();
};

void AsyncProcessTest::largeOutputIsFullyCaptured()
{
    // 20 000 lines (~130 KB) — far past the 64 KB pipe buffer, so the
    // readyRead handler must run several times before the process ends.
    AsyncProcess process;
    QEventLoop loop;
    QString output;
    bool ok = false;
    int exitCode = -1;

    QObject::connect(&process, &AsyncProcess::finished,
                     &loop, [&](bool success, int code, const QString &text) {
        ok = success;
        exitCode = code;
        output = text;
        loop.quit();
    });

    // seq is in coreutils; no shell involved — arguments stay separate.
    process.start(QStringLiteral("seq"), { QStringLiteral("1"),
                                           QStringLiteral("20000") });

    QTimer timer;
    timer.setSingleShot(true);
    QObject::connect(&timer, &QTimer::timeout, &loop, &QEventLoop::quit);
    timer.start(15000);
    loop.exec();

    QVERIFY2(ok, "seq should exit successfully");
    QCOMPARE(exitCode, 0);

    const QStringList lines = output.trimmed().split(QLatin1Char('\n'));
    QCOMPARE(lines.size(), 20000);
    QCOMPARE(lines.first(), QStringLiteral("1"));
    QCOMPARE(lines.last(), QStringLiteral("20000"));
}

void AsyncProcessTest::failingProcessReportsExitCode()
{
    // false(1) exits with code 1 and produces no output.
    AsyncProcess process;
    QEventLoop loop;
    bool ok = true;
    int exitCode = -1;

    QObject::connect(&process, &AsyncProcess::finished,
                     &loop, [&](bool success, int code, const QString &) {
        ok = success;
        exitCode = code;
        loop.quit();
    });

    process.start(QStringLiteral("false"), {});
    QTimer timer;
    timer.setSingleShot(true);
    QObject::connect(&timer, &QTimer::timeout, &loop, &QEventLoop::quit);
    timer.start(15000);
    loop.exec();

    QVERIFY(!ok);
    QCOMPARE(exitCode, 1);
}

QTEST_GUILESS_MAIN(AsyncProcessTest)
#include "tst_asyncprocess.moc"
