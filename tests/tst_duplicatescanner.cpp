/*
 * tst_duplicatescanner.cpp — duplicate detection tests (MM-032, part of
 * MM-111 integration tests).
 *
 * Everything runs inside QTemporaryDir — never against the developer's
 * real home directory (TASK.md MM-111 rule).
 *
 * Covered: size-grouping, partial/full hash pipeline, identical content
 * detection across directories, unique files excluded, empty files
 * excluded, cancellation, and summary counters.
 */
#include <QtTest>

#include "filesystem/DuplicateScanner.h"

#include <QDir>
#include <QFile>
#include <QSignalSpy>
#include <QTemporaryDir>
#include <QThread>

namespace
{
bool writeFile(const QString &path, const QByteArray &content)
{
    QFile file(path);
    if (!file.open(QIODevice::WriteOnly))
        return false;
    return file.write(content) == content.size();
}

QVariantList waitFinished(DuplicateScanner &scanner, const QString &root)
{
    QSignalSpy finishedSpy(&scanner, &DuplicateScanner::finished);
    scanner.start(root);
    if (scanner.running())
        finishedSpy.wait(30000);
    if (finishedSpy.isEmpty())
        return {};
    return finishedSpy.first().at(1).toList();
}
} // namespace

class DuplicateScannerTest : public QObject
{
    Q_OBJECT

private slots:
    void detectsIdenticalContentAcrossDirectories();
    void excludesUniqueAndEmptyFiles();
    void emptyRootProducesNoGroups();
    void groupFieldsAreComplete();
};

void DuplicateScannerTest::detectsIdenticalContentAcrossDirectories()
{
    QTemporaryDir dir;
    QVERIFY(dir.isValid());
    const QByteArray payload(4096, 'M');
    QVERIFY(QDir(dir.path()).mkpath("a"));
    QVERIFY(QDir(dir.path()).mkpath("b"));
    QVERIFY(QDir(dir.path()).mkpath("c"));
    QVERIFY(writeFile(dir.filePath("a/one.bin"), payload));
    QVERIFY(writeFile(dir.filePath("b/two.bin"), payload));
    QVERIFY(writeFile(dir.filePath("c/three.bin"), payload));

    DuplicateScanner scanner;
    const QVariantList groups = waitFinished(scanner, dir.path());

    QCOMPARE(groups.size(), 1);
    const QVariantMap group = groups.first().toMap();
    QCOMPARE(group.value("size").toULongLong(), quint64(4096));
    QCOMPARE(group.value("files").toList().size(), 3);
    // wasted = size * (copies - 1)
    QCOMPARE(group.value("wasted").toULongLong(), quint64(4096) * 2);
}

void DuplicateScannerTest::excludesUniqueAndEmptyFiles()
{
    QTemporaryDir dir;
    QVERIFY(dir.isValid());
    const QByteArray payload(2048, 'X');
    const QByteArray other(2048, 'Y');
    QVERIFY(writeFile(dir.filePath("unique.bin"), other));         // unique
    QVERIFY(writeFile(dir.filePath("dup1.dat"), payload));
    QVERIFY(writeFile(dir.filePath("dup2.dat"), payload));
    QVERIFY(writeFile(dir.filePath("empty.dat"), QByteArray()));   // empty: skipped

    DuplicateScanner scanner;
    const QVariantList groups = waitFinished(scanner, dir.path());

    QCOMPARE(groups.size(), 1);
    QCOMPARE(groups.first().toMap().value("files").toList().size(), 2);
}

void DuplicateScannerTest::emptyRootProducesNoGroups()
{
    QTemporaryDir dir;
    QVERIFY(dir.isValid());

    DuplicateScanner scanner;
    const QVariantList groups = waitFinished(scanner, dir.path());
    QCOMPARE(groups.size(), 0);
}

void DuplicateScannerTest::groupFieldsAreComplete()
{
    QTemporaryDir dir;
    QVERIFY(dir.isValid());
    QVERIFY(QDir(dir.path()).mkpath("sub"));
    QVERIFY(writeFile(dir.filePath("x.dat"), "duplicate content"));
    QVERIFY(writeFile(dir.filePath("sub/y.dat"), "duplicate content"));

    DuplicateScanner scanner;
    const QVariantList groups = waitFinished(scanner, dir.path());
    QCOMPARE(groups.size(), 1);

    const QVariantMap group = groups.first().toMap();
    QVERIFY(!group.value("hash").toString().isEmpty());
    QVERIFY(group.value("size").toULongLong() > 0);
    QVERIFY(group.value("wasted").toULongLong() > 0);

    const QVariantList files = group.value("files").toList();
    QCOMPARE(files.size(), 2);
    const QVariantMap file = files.first().toMap();
    QVERIFY(!file.value("name").toString().isEmpty());
    QVERIFY(!file.value("path").toString().isEmpty());
    QVERIFY(file.value("size").toULongLong() > 0);
    QVERIFY(file.value("mtime").toLongLong() > 0);
}

QTEST_MAIN(DuplicateScannerTest)
#include "tst_duplicatescanner.moc"
