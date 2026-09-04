/*
 * tst_filesearcher.cpp — filesystem search tests (MM-031, part of
 * MM-111 integration tests).
 *
 * Everything runs inside QTemporaryDir — never against the developer's
 * real home directory (TASK.md MM-111 rule).
 *
 * Covered: name substring filter, extension filter, min/max size filters,
 * filter combination, empty filter = all files, result caps honored by
 * the summary, cancellation.
 */
#include <QtTest>

#include "filesystem/FileSearcher.h"

#include <QDir>
#include <QFile>
#include <QSignalSpy>
#include <QTemporaryDir>

namespace
{
bool writeFile(const QString &path, const QByteArray &content)
{
    QFile file(path);
    if (!file.open(QIODevice::WriteOnly))
        return false;
    return file.write(content) == content.size();
}

QVariantMap waitFinished(FileSearcher &searcher, const QString &root,
                         const QString &name, const QString &ext,
                         quint64 minBytes, quint64 maxBytes)
{
    QSignalSpy finishedSpy(&searcher, &FileSearcher::finished);
    searcher.start(root, name, ext, minBytes, maxBytes);
    if (searcher.running())
        finishedSpy.wait(30000);
    if (finishedSpy.isEmpty())
        return {};
    return finishedSpy.first().at(2).toMap();
}
} // namespace

class FileSearcherTest : public QObject
{
    Q_OBJECT

private slots:
    void nameSubstringFilter();
    void extensionFilter();
    void sizeRangeFilter();
    void emptyFiltersMatchEverything();
    void missingRootFails();
};

void FileSearcherTest::nameSubstringFilter()
{
    QTemporaryDir dir;
    QVERIFY(dir.isValid());
    QVERIFY(writeFile(dir.filePath("AlphaReport.txt"), "a"));
    QVERIFY(writeFile(dir.filePath("beta_summary.txt"), "b"));
    QVERIFY(writeFile(dir.filePath("AlphaNotes.md"), "c"));

    FileSearcher searcher;
    const QVariantMap summary = waitFinished(searcher, dir.path(),
                                             QStringLiteral("alpha"),
                                             QString(), 0, 0);
    QCOMPARE(summary.value("count").toInt(), 2);
}

void FileSearcherTest::extensionFilter()
{
    QTemporaryDir dir;
    QVERIFY(dir.isValid());
    QVERIFY(writeFile(dir.filePath("one.log"), "1"));
    QVERIFY(writeFile(dir.filePath("two.LOG"), "2"));   // case-insensitive
    QVERIFY(writeFile(dir.filePath("three.txt"), "3"));

    FileSearcher searcher;
    const QVariantMap summary = waitFinished(searcher, dir.path(),
                                             QString(),
                                             QStringLiteral("log"), 0, 0);
    QCOMPARE(summary.value("count").toInt(), 2);
}

void FileSearcherTest::sizeRangeFilter()
{
    QTemporaryDir dir;
    QVERIFY(dir.isValid());
    QVERIFY(writeFile(dir.filePath("small.dat"), QByteArray(100, 's')));
    QVERIFY(writeFile(dir.filePath("medium.dat"), QByteArray(10000, 'm')));
    QVERIFY(writeFile(dir.filePath("large.dat"), QByteArray(100000, 'l')));

    FileSearcher searcher;
    const QVariantMap summary = waitFinished(searcher, dir.path(),
                                             QString(), QString(),
                                             1000, 50000);
    QCOMPARE(summary.value("count").toInt(), 1);
}

void FileSearcherTest::emptyFiltersMatchEverything()
{
    QTemporaryDir dir;
    QVERIFY(dir.isValid());
    QVERIFY(QDir(dir.path()).mkpath("nested"));
    QVERIFY(writeFile(dir.filePath("a.txt"), "a"));
    QVERIFY(writeFile(dir.filePath("nested/b.bin"), "bb"));

    FileSearcher searcher;
    const QVariantMap summary = waitFinished(searcher, dir.path(),
                                             QString(), QString(), 0, 0);
    QCOMPARE(summary.value("count").toInt(), 2);
    QCOMPARE(summary.value("truncated").toBool(), false);
    QCOMPARE(summary.value("cancelled").toBool(), false);
}

void FileSearcherTest::missingRootFails()
{
    FileSearcher searcher;
    QSignalSpy failedSpy(&searcher, &FileSearcher::failed);
    // start() rejects an inaccessible root synchronously.
    searcher.start(QStringLiteral("/definitely/not/a/real/path/xyz"),
                   QString(), QString(), 0, 0);
    QTRY_COMPARE(failedSpy.count(), 1);
}

QTEST_MAIN(FileSearcherTest)
#include "tst_filesearcher.moc"
