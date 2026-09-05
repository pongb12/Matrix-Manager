/*
 * tst_packagemodel.cpp — unit tests for the package list model:
 * category classification from dpkg sections, category filtering,
 * section-ordered views and the category summary (1.0.3-2).
 */
#include <QSet>
#include <QtTest>

#include "packages/PackageModel.h"

namespace
{
PackageEntry entry(const QString &name, const QString &section, quint64 kib)
{
    PackageEntry e;
    e.name = name;
    e.version = QStringLiteral("1.0");
    e.architecture = QStringLiteral("amd64");
    e.summary = name;
    e.section = section;
    e.installedSizeBytes = kib * 1024ull;
    return e;
}
} // namespace

class PackageModelTest : public QObject
{
    Q_OBJECT

private slots:
    void classifiesSections();
    void viewsSortByCategoryThenSize();
    void categoryFilter();
    void filterMatchesSectionText();
    void categorySummaryCounts();
    void getExposesCategory();
};

void PackageModelTest::classifiesSections()
{
    // Base Debian sections map to their category.
    QCOMPARE(PackageModel::categoryIdForSection(QStringLiteral("web")),
             QStringLiteral("internet"));
    QCOMPARE(PackageModel::categoryIdForSection(QStringLiteral("utils")),
             QStringLiteral("accessories"));
    QCOMPARE(PackageModel::categoryIdForSection(QStringLiteral("devel")),
             QStringLiteral("development"));
    QCOMPARE(PackageModel::categoryIdForSection(QStringLiteral("sound")),
             QStringLiteral("multimedia"));
    QCOMPARE(PackageModel::categoryIdForSection(QStringLiteral("libs")),
             QStringLiteral("libraries"));
    QCOMPARE(PackageModel::categoryIdForSection(QStringLiteral("gnome")),
             QStringLiteral("desktop"));

    // Ubuntu/Mint archive prefixes are stripped before matching.
    QCOMPARE(PackageModel::categoryIdForSection(QStringLiteral("universe/web")),
             QStringLiteral("internet"));
    QCOMPARE(PackageModel::categoryIdForSection(QStringLiteral("multiverse/sound")),
             QStringLiteral("multimedia"));
    QCOMPARE(PackageModel::categoryIdForSection(QStringLiteral("contrib/utils")),
             QStringLiteral("accessories"));

    // Case-insensitive, unknown and empty sections land in "other".
    QCOMPARE(PackageModel::categoryIdForSection(QStringLiteral("WEB")),
             QStringLiteral("internet"));
    QCOMPARE(PackageModel::categoryIdForSection(QStringLiteral("hamradio-xyz")),
             QStringLiteral("other"));
    QCOMPARE(PackageModel::categoryIdForSection(QString()),
             QStringLiteral("other"));
}

void PackageModelTest::viewsSortByCategoryThenSize()
{
    PackageModel model;
    QVector<PackageEntry> entries;
    entries.append(entry(QStringLiteral("firefox"), QStringLiteral("web"), 254000));
    entries.append(entry(QStringLiteral("gcc"), QStringLiteral("devel"), 90000));
    entries.append(entry(QStringLiteral("nano"), QStringLiteral("editors"), 550));
    entries.append(entry(QStringLiteral("vlc"), QStringLiteral("video"), 70000));
    entries.append(entry(QStringLiteral("weird"), QStringLiteral("zzz"), 10));
    model.resetFrom(entries);

    // Category rank order: accessories < internet < development < ... <
    // multimedia < other. Sizes are descending (the default sort) inside
    // each group.
    QCOMPARE(model.get(0).value("packageName").toString(), QStringLiteral("nano"));
    QCOMPARE(model.get(1).value("packageName").toString(), QStringLiteral("firefox"));
    QCOMPARE(model.get(2).value("packageName").toString(), QStringLiteral("gcc"));
    QCOMPARE(model.get(3).value("packageName").toString(), QStringLiteral("vlc"));
    QCOMPARE(model.get(4).value("packageName").toString(), QStringLiteral("weird"));

    // Each category id must form one contiguous block so the ListView
    // sections render exactly one header per group.
    QString current;
    QSet<QString> seen;
    for (int i = 0; i < model.count(); ++i) {
        const QString id = model.get(i).value("categoryId").toString();
        if (id != current) {
            QVERIFY2(!seen.contains(id), "category ids must be contiguous");
            seen.insert(id);
            current = id;
        }
    }
}

void PackageModelTest::categoryFilter()
{
    PackageModel model;
    QVector<PackageEntry> entries;
    entries.append(entry(QStringLiteral("firefox"), QStringLiteral("web"), 254000));
    entries.append(entry(QStringLiteral("gcc"), QStringLiteral("devel"), 90000));
    entries.append(entry(QStringLiteral("nano"), QStringLiteral("editors"), 550));
    model.resetFrom(entries);

    model.setCategory(QStringLiteral("development"));
    QCOMPARE(model.count(), 1);
    QCOMPARE(model.get(0).value("packageName").toString(), QStringLiteral("gcc"));

    // "all" and "" both mean every category.
    model.setCategory(QStringLiteral("all"));
    QCOMPARE(model.count(), 3);
    model.setCategory(QString());
    QCOMPARE(model.count(), 3);

    // Selecting an empty category yields an empty view, not a crash.
    model.setCategory(QStringLiteral("fonts"));
    QCOMPARE(model.count(), 0);
}

void PackageModelTest::filterMatchesSectionText()
{
    PackageModel model;
    QVector<PackageEntry> entries;
    entries.append(entry(QStringLiteral("pkg-a"), QStringLiteral("web"), 100));
    entries.append(entry(QStringLiteral("pkg-b"), QStringLiteral("devel"), 200));
    model.resetFrom(entries);

    // Searching for "web" matches pkg-a through its section text.
    model.setFilter(QStringLiteral("web"));
    QCOMPARE(model.count(), 1);
    QCOMPARE(model.get(0).value("packageName").toString(), QStringLiteral("pkg-a"));

    model.setFilter(QStringLiteral("DEVEL")); // case-insensitive
    QCOMPARE(model.count(), 1);
    QCOMPARE(model.get(0).value("packageName").toString(), QStringLiteral("pkg-b"));
}

void PackageModelTest::categorySummaryCounts()
{
    PackageModel model;
    QVector<PackageEntry> entries;
    entries.append(entry(QStringLiteral("firefox"), QStringLiteral("web"), 254000));
    entries.append(entry(QStringLiteral("thunderbird"), QStringLiteral("mail"), 120000));
    entries.append(entry(QStringLiteral("gcc"), QStringLiteral("universe/devel"), 90000));
    entries.append(entry(QStringLiteral("make"), QStringLiteral("devel"), 5000));
    entries.append(entry(QStringLiteral("mystery"), QString(), 42));
    model.resetFrom(entries);

    const QVariantList summary = model.categorySummary();
    QCOMPARE(summary.size(), 3); // internet, development, other — ordered

    const QVariantMap first = summary.at(0).toMap();
    QCOMPARE(first.value("id").toString(), QStringLiteral("internet"));
    QCOMPARE(first.value("count").toInt(), 2);
    QCOMPARE(first.value("bytes").toULongLong(),
             (254000ull + 120000ull) * 1024ull);

    const QVariantMap second = summary.at(1).toMap();
    QCOMPARE(second.value("id").toString(), QStringLiteral("development"));
    QCOMPARE(second.value("count").toInt(), 2);

    const QVariantMap third = summary.at(2).toMap();
    QCOMPARE(third.value("id").toString(), QStringLiteral("other"));
    QCOMPARE(third.value("bytes").toULongLong(), 42ull * 1024ull);

    // The summary is independent of the current category filter (it feeds
    // the chip row, which must stay clickable to switch back).
    model.setCategory(QStringLiteral("development"));
    QCOMPARE(model.categorySummary().size(), 3);
}

void PackageModelTest::getExposesCategory()
{
    PackageModel model;
    QVector<PackageEntry> entries;
    entries.append(entry(QStringLiteral("firefox"), QStringLiteral("universe/web"), 254000));
    model.resetFrom(entries);

    QCOMPARE(model.get(0).value("categoryId").toString(), QStringLiteral("internet"));
}

QTEST_MAIN(PackageModelTest)
#include "tst_packagemodel.moc"
