#include "CleanupService.h"

#include "core/ActivityLog.h"
#include "core/SizeUtils.h"
#include "filesystem/FileWalker.h"
#include "platform/linux/ProcessRunner.h"

#include <QDir>
#include <QEventLoop>
#include <QFile>
#include <QStandardPaths>
#include <QTimer>

namespace
{

// Recursively sums the size of all regular files below path (no symlink
// following, no filesystem crossing — conservative on purpose).
quint64 pathSize(const QString &path, quint64 *fileCount)
{
    quint64 total = 0;
    quint64 count = 0;

    QFileInfo info(path);
    if (info.isSymLink())
        return 0;
    if (info.isFile()) {
        if (fileCount)
            ++*fileCount;
        return static_cast<quint64>(info.size());
    }
    if (!info.isDir())
        return 0;

    // Manual stack walk instead of QDirIterator: symlinked directories must
    // never be traversed (DOC.md rule 8), and symlink entries contribute 0.
    QVector<QString> stack;
    stack.append(path);
    while (!stack.isEmpty()) {
        const QDir dir(stack.takeLast());
        const QFileInfoList entries =
            dir.entryInfoList(QDir::AllEntries | QDir::Hidden | QDir::NoDotAndDotDot);
        for (const QFileInfo &entry : entries) {
            if (entry.isSymLink())
                continue;
            if (entry.isDir()) {
                stack.append(entry.absoluteFilePath());
            } else if (entry.isFile()) {
                total += static_cast<quint64>(entry.size());
                ++count;
            }
        }
    }

    if (fileCount)
        *fileCount = count;
    return total;
}

} // namespace

CleanupService *CleanupService::instance()
{
    static CleanupService service;
    return &service;
}

CleanupService::CleanupService(QObject *parent)
    : QObject(parent)
{
    CleanupRule trash;
    trash.id = QStringLiteral("user-trash");
    trash.name = QStringLiteral("Trash");
    trash.description =
        QStringLiteral("Files you have deleted that are still recoverable from the "
                       "system trash. Emptying the trash permanently removes them.");
    trash.consequence =
        QStringLiteral("Everything currently in the trash will be permanently deleted. "
                       "This cannot be undone.");
    trash.targets = { QStringLiteral("~/.local/share/Trash") };
    trash.risk = LowRisk;
    trash.requiresPrivilege = false;
    m_rules.append(trash);

    CleanupRule apt;
    apt.id = QStringLiteral("apt-cache");
    apt.name = QStringLiteral("APT package cache");
    apt.description =
        QStringLiteral("Downloaded .deb package archives kept in the APT cache. "
                       "They are only needed for offline reinstalling and are "
                       "re-downloaded automatically when required.");
    apt.consequence =
        QStringLiteral("Cached package archives will be deleted using 'apt-get clean'. "
                       "Installed software is not affected. Packages can be "
                       "re-downloaded from their repositories at any time.");
    apt.targets = { QStringLiteral("/var/cache/apt/archives") };
    apt.risk = LowRisk;
    apt.requiresPrivilege = true;
    m_rules.append(apt);

    CleanupRule thumbs;
    thumbs.id = QStringLiteral("thumbnail-cache");
    thumbs.name = QStringLiteral("Thumbnail cache");
    thumbs.description =
        QStringLiteral("Preview images generated for pictures and videos. They are "
                       "recreated automatically as you browse your files.");
    thumbs.consequence =
        QStringLiteral("Cached thumbnails will be deleted. File managers will "
                       "regenerate them as needed; no user files are touched.");
    thumbs.targets = { QStringLiteral("~/.cache/thumbnails") };
    thumbs.risk = MediumRisk;
    thumbs.requiresPrivilege = false;
    m_rules.append(thumbs);
}

const CleanupService::CleanupRule *CleanupService::ruleById(const QString &id) const
{
    for (const CleanupRule &rule : m_rules) {
        if (rule.id == id)
            return &rule;
    }
    return nullptr;
}

QString CleanupService::trashRootPath()
{
    const QString dataHome =
        QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation);
    const QString candidate = dataHome + QStringLiteral("/Trash");
    // Fall back to the XDG default when XDG_DATA_HOME is not set.
    if (QDir(candidate).exists())
        return candidate;
    const QString home = QDir::homePath();
    return home + QStringLiteral("/.local/share/Trash");
}

bool CleanupService::isSafeSubPath(const QString &canonicalRoot,
                                   const QString &candidatePath)
{
    if (canonicalRoot.isEmpty() || candidatePath.isEmpty())
        return false;
    const QString root = QDir(canonicalRoot).canonicalPath();
    if (root.isEmpty()) {
        // The root cannot be resolved (never created, deleted, or a
        // dangling symlink). Refuse to open the guard: callers only ever
        // delete entries meant to live under root, and an unresolvable
        // root must never widen the check to "everything". Regression:
        // on a fresh machine an empty root made startsWith("") accept
        // any existing path such as /etc/passwd.
        return false;
    }
    QString candidate = QDir(candidatePath).canonicalPath();
    if (candidate.isEmpty()) {
        // The entry may already be gone; compare what exists of the chain.
        candidate = QDir::cleanPath(candidatePath);
    }
    if (!candidate.startsWith(root))
        return false;
    if (candidate.size() > root.size()
        && candidate.at(root.size()) != QLatin1Char('/'))
        return false;
    return true;
}

QVariantList CleanupService::rules() const
{
    QVariantList list;
    for (const CleanupRule &rule : m_rules) {
        QVariantMap map;
        map.insert(QStringLiteral("id"), rule.id);
        map.insert(QStringLiteral("name"), rule.name);
        map.insert(QStringLiteral("description"), rule.description);
        map.insert(QStringLiteral("consequence"), rule.consequence);
        map.insert(QStringLiteral("targets"), rule.targets);
        map.insert(QStringLiteral("riskLevel"), static_cast<int>(rule.risk));
        map.insert(QStringLiteral("risk"),
                   rule.risk == LowRisk ? QStringLiteral("LOW")
                       : rule.risk == MediumRisk ? QStringLiteral("MEDIUM")
                                                 : QStringLiteral("HIGH"));
        map.insert(QStringLiteral("requiresPrivilege"), rule.requiresPrivilege);
        list.append(map);
    }
    return list;
}

QVariantMap CleanupService::estimate(const QString &ruleId)
{
    QVariantMap result;
    if (ruleId == QLatin1String("user-trash"))
        result = estimateTrash();
    else if (ruleId == QLatin1String("apt-cache"))
        result = estimateAptCache();
    else if (ruleId == QLatin1String("thumbnail-cache"))
        result = estimateThumbnails();
    else
        result.insert(QStringLiteral("error"),
                      QStringLiteral("Unknown cleanup rule '%1'").arg(ruleId));
    return result;
}

QVariantMap CleanupService::estimateTrash()
{
    QVariantMap result;
    quint64 count = 0;
    const QString trashRoot = trashRootPath();
    const quint64 bytes = pathSize(trashRoot + QStringLiteral("/files"), &count);
    // .trashinfo metadata files are counted separately from trashed content.
    quint64 infoCount = 0;
    pathSize(trashRoot + QStringLiteral("/info"), &infoCount);
    result.insert(QStringLiteral("bytes"), bytes);
    result.insert(QStringLiteral("itemCount"), count + infoCount);
    result.insert(QStringLiteral("exists"), QDir(trashRoot).exists());
    return result;
}

QVariantMap CleanupService::estimateAptCache()
{
    QVariantMap result;
    quint64 count = 0;
    const QDir cacheDir(QStringLiteral("/var/cache/apt/archives"));
    quint64 bytes = 0;
    if (cacheDir.exists()) {
        const QFileInfoList entries =
            cacheDir.entryInfoList(QStringList() << QStringLiteral("*.deb"),
                                   QDir::Files | QDir::NoDotAndDotDot);
        for (const QFileInfo &entry : entries) {
            bytes += static_cast<quint64>(entry.size());
            ++count;
        }
    }
    result.insert(QStringLiteral("bytes"), bytes);
    result.insert(QStringLiteral("itemCount"), count);
    result.insert(QStringLiteral("exists"), cacheDir.exists());
    return result;
}

QVariantMap CleanupService::estimateThumbnails()
{
    QVariantMap result;
    quint64 count = 0;
    const QString dir = QDir::homePath() + QStringLiteral("/.cache/thumbnails");
    const quint64 bytes = pathSize(dir, &count);
    result.insert(QStringLiteral("bytes"), bytes);
    result.insert(QStringLiteral("itemCount"), count);
    result.insert(QStringLiteral("exists"), QDir(dir).exists());
    return result;
}

// ---------------------------------------------------------------------------

void CleanupService::clean(const QStringList &ruleIds)
{
    if (m_running || ruleIds.isEmpty())
        return;

    // Only accept known rule ids — never execute anything arbitrary.
    QStringList ids;
    for (const QString &id : ruleIds) {
        if (ruleById(id))
            ids.append(id);
    }
    if (ids.isEmpty())
        return;

    m_running = true;
    m_stopRequested = false;
    m_pendingRules = ids;
    emit runningChanged();
    runNextRule();
}

void CleanupService::stopAfterCurrent()
{
    m_stopRequested = true;
}

void CleanupService::runNextRule()
{
    if (m_stopRequested || m_pendingRules.isEmpty()) {
        m_running = false;
        emit runningChanged();
        emit allFinished();
        return;
    }

    const QString id = m_pendingRules.takeFirst();
    const CleanupRule *rule = ruleById(id);
    if (!rule) {
        runNextRule();
        return;
    }

    emit ruleStarted(id);

    quint64 freed = 0;
    QString error;
    bool ok = false;

    if (id == QLatin1String("user-trash"))
        ok = emptyTrash(&freed, &error);
    else if (id == QLatin1String("apt-cache"))
        ok = cleanAptCache(&freed, &error);
    else if (id == QLatin1String("thumbnail-cache"))
        ok = cleanThumbnails(&freed, &error);

    if (ok) {
        ActivityLog::instance()->add(
            QStringLiteral("Cleaned: %1").arg(rule->name),
            QStringLiteral("Freed %1").arg(SizeUtils::formatBytes(freed)));
    }
    emit ruleFinished(id, ok, freed, error);
    runNextRule();
}

quint64 CleanupService::removeEntry(const QString &entryPath, bool *ok)
{
    *ok = false;
    if (entryPath == QDir::homePath() || entryPath == QLatin1String("/"))
        return 0; // paranoid guard, should never happen

    QFileInfo info(entryPath);
    quint64 size = 0;
    quint64 count = 0;
    if (info.isDir() && !info.isSymLink())
        size = pathSize(entryPath, &count);
    else if (info.isFile())
        size = static_cast<quint64>(info.size());

    bool removed = false;
    if (info.isDir() && !info.isSymLink())
        removed = QDir(entryPath).removeRecursively();
    else
        removed = QFile::remove(entryPath);

    *ok = removed;
    return removed ? size : 0;
}

bool CleanupService::emptyTrash(quint64 *freedBytes, QString *error)
{
    const QString trashRoot = QDir(trashRootPath()).canonicalPath();
    if (trashRoot.isEmpty() || !QDir(trashRoot).exists()) {
        *freedBytes = 0;
        *error = {};
        return true; // nothing to do is a success
    }

    // Safety contract: only ever touch directories inside the trash root.
    const QString filesDir = trashRoot + QStringLiteral("/files");
    const QString infoDir = trashRoot + QStringLiteral("/info");
    quint64 freed = 0;
    int failures = 0;

    const QFileInfoList entries =
        QDir(filesDir).entryInfoList(QDir::AllEntries | QDir::Hidden
                                         | QDir::NoDotAndDotDot);
    for (const QFileInfo &entry : entries) {
        if (!isSafeSubPath(filesDir, entry.absoluteFilePath())) {
            ++failures;
            continue;
        }
        bool ok = false;
        freed += removeEntry(entry.absoluteFilePath(), &ok);
        if (!ok)
            ++failures;

        // Remove matching .trashinfo metadata (best effort).
        const QString infoFile =
            infoDir + QStringLiteral("/%1.trashinfo").arg(entry.fileName());
        if (isSafeSubPath(infoDir, infoFile))
            QFile::remove(infoFile);
    }

    if (failures > 0 && freed == 0) {
        *error = QStringLiteral("Could not remove %1 trash entries").arg(failures);
        *freedBytes = freed;
        return false;
    }
    if (failures > 0) {
        *error = QStringLiteral("%1 entries could not be removed").arg(failures);
    }
    *freedBytes = freed;
    return true;
}

bool CleanupService::cleanAptCache(quint64 *freedBytes, QString *error)
{
    QVariantMap estimate = estimateAptCache();
    const quint64 bytes = estimate.value(QStringLiteral("bytes")).toULongLong();

    // Use the system's own mechanism, never manual deletion (AGENT.md rule 10).
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("DEBIAN_FRONTEND"), QStringLiteral("noninteractive"));

    AsyncProcess process;
    QString output;
    bool finished = false;
    bool ok = false;

    connect(&process, &AsyncProcess::outputChunk, this,
            [&output](const QString &chunk) {
        output += chunk;
        if (output.size() > 16 * 1024)
            output = output.mid(output.size() - 16 * 1024);
    });

    QEventLoop loop;
    connect(&process, &AsyncProcess::finished, this,
            [&](bool success, int exitCode, const QString &) {
        ok = success && exitCode == 0;
        finished = true;
        loop.quit();
    });

    // pkexec resets the environment; use `env` to pass DEBIAN_FRONTEND.
    process.start(QStringLiteral("pkexec"),
                  { QStringLiteral("env"),
                    QStringLiteral("DEBIAN_FRONTEND=noninteractive"),
                    QStringLiteral("apt-get"),
                    QStringLiteral("clean") },
                  env);

    // The process may fail to start synchronously; only wait when needed.
    if (!finished) {
        QTimer timeout;
        timeout.setSingleShot(true);
        timeout.start(10 * 60 * 1000);
        connect(&timeout, &QTimer::timeout, &loop, &QEventLoop::quit);
        loop.exec(); // nested loop keeps the GUI responsive while apt runs
    }

    if (!finished) {
        process.kill();
        *error = QStringLiteral("APT cache cleanup timed out");
        return false;
    }
    if (!ok) {
        *error = QStringLiteral("Authorization denied or 'apt-get clean' failed")
                     + (output.isEmpty() ? QString()
                                         : QStringLiteral(": %1").arg(output.section(
                                               QLatin1Char('\n'), -1).trimmed()));
        return false;
    }

    *freedBytes = bytes;
    return true;
}

bool CleanupService::cleanThumbnails(quint64 *freedBytes, QString *error)
{
    const QString root =
        QDir(QDir::homePath() + QStringLiteral("/.cache/thumbnails")).canonicalPath();
    if (root.isEmpty() || !QDir(root).exists()) {
        *freedBytes = 0;
        return true;
    }

    quint64 freed = 0;
    int failures = 0;
    const QFileInfoList entries =
        QDir(root).entryInfoList(QDir::AllEntries | QDir::Hidden
                                     | QDir::NoDotAndDotDot);
    for (const QFileInfo &entry : entries) {
        if (!isSafeSubPath(root, entry.absoluteFilePath())) {
            ++failures;
            continue;
        }
        bool ok = false;
        freed += removeEntry(entry.absoluteFilePath(), &ok);
        if (!ok)
            ++failures;
    }

    if (failures > 0 && freed == 0) {
        *error = QStringLiteral("Could not remove %1 cache entries").arg(failures);
        return false;
    }
    if (failures > 0)
        *error = QStringLiteral("%1 entries could not be removed").arg(failures);
    *freedBytes = freed;
    return true;
}
