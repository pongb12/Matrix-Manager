/*
 * tst_sizeutils.cpp — unit tests for size formatting (MM-110).
 *
 * DOC.md rule 7 fixes one convention: binary units, one decimal place
 * (except plain bytes). These tests pin that convention.
 */
#include <QtTest>

#include "core/SizeUtils.h"

using namespace SizeUtils;

class SizeUtilsTest : public QObject
{
    Q_OBJECT

private slots:
    void bytesAreInteger();
    void kibHasOneDecimal();
    void mibRange();
    void gibRange();
    void tibRange();
    void zero();
    void kibConversion();
};

void SizeUtilsTest::bytesAreInteger()
{
    QCOMPARE(formatBytes(0), QStringLiteral("0 B"));
    QCOMPARE(formatBytes(1), QStringLiteral("1 B"));
    QCOMPARE(formatBytes(512), QStringLiteral("512 B"));
    QCOMPARE(formatBytes(1023), QStringLiteral("1023 B"));
}

void SizeUtilsTest::kibHasOneDecimal()
{
    QCOMPARE(formatBytes(1024), QStringLiteral("1.0 KiB"));
    QCOMPARE(formatBytes(1536), QStringLiteral("1.5 KiB"));
}

void SizeUtilsTest::mibRange()
{
    // 42.7 MiB — the DOC.md example.
    const quint64 mib = 42 * 1024ull * 1024ull + static_cast<quint64>(0.7 * 1024 * 1024);
    QVERIFY(formatBytes(mib).startsWith(QStringLiteral("42.")));
    QVERIFY(formatBytes(mib).endsWith(QStringLiteral(" MiB")));
}

void SizeUtilsTest::gibRange()
{
    QCOMPARE(formatBytes(1 * 1024ull * 1024ull * 1024ull),
             QStringLiteral("1.0 GiB"));
    // 1.8 GiB — the DOC.md example.
    const quint64 gib8 = static_cast<quint64>(1.8 * 1024 * 1024 * 1024);
    QVERIFY(formatBytes(gib8).startsWith(QStringLiteral("1.8 GiB")));
}

void SizeUtilsTest::tibRange()
{
    QCOMPARE(formatBytes(1ull * 1024ull * 1024ull * 1024ull * 1024ull),
             QStringLiteral("1.0 TiB"));
}

void SizeUtilsTest::zero()
{
    QCOMPARE(formatBytes(0), QStringLiteral("0 B"));
}

void SizeUtilsTest::kibConversion()
{
    QCOMPARE(kibToBytes(1), 1024ull);
    QCOMPARE(formatKib(1024), QStringLiteral("1.0 MiB"));
}

QTEST_MAIN(SizeUtilsTest)
#include "tst_sizeutils.moc"
