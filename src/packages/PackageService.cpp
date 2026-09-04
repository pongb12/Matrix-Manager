#include "PackageService.h"

#include "core/ActivityLog.h"
#include "core/SizeUtils.h"

#include <QProcessEnvironment>

namespace
{
// dpkg-query format: one package per line, tab-separated fields.
// ${binary:Summary} is guaranteed single-line; ${Description} is not used
// because it is multi-line and would break the record format.
const char kDpkgQueryFormat[] =
    "${Package}\\t${db:Status-Status}\\t${Version}\\t${Architecture}"
    "\\t${Installed-Size}\\t${Section}\\t${binary:Summary}\\n";
}

PackageService *PackageService::instance()
{
    static PackageService service;
    return &service;
}

const QRegularExpression &PackageService::packageNameRegex()
{
    // Debian package names: lower-case letters, digits, '+', '-', '.'.
    // Must start with a letter or digit. Anchored to prevent injection.
    static const QRegularExpression regex(
        QStringLiteral("^[a-z0-9][a-z0-9+.-]*$"));
    return regex;
}

bool PackageService::isValidPackageName(const QString &name)
{
    if (name.isEmpty() || name.length() > 200)
        return false;
    return packageNameRegex().match(name).hasMatch();
}

PackageService::PackageService(QObject *parent)
    : QObject(parent)
    , m_model(new PackageModel(this))
{
    connect(&m_process, &AsyncProcess::outputChunk, this,
            [this](const QString &text) {
        if (m_busy)
            appendOperationOutput(text);
    });
    connect(&m_process, &AsyncProcess::finished, this,
            [this](bool success, int exitCode, const QString &output) {
        if (m_loading) {
            // dpkg-query finished
            setLoading(false);
            if (!success) {
                setLastError(QStringLiteral(
                                  "Could not query installed packages (exit code %1). %2")
                                  .arg(exitCode)
                                  .arg(output.section(QLatin1Char('\n'), -1).trimmed()));
                emit refreshFinished(false, 0, m_lastError);
                return;
            }
            const QVector<PackageEntry> entries = parseDpkgQueryOutput(output);
            m_model->resetFrom(entries);
            setLastError({});
            emit refreshFinished(true, entries.size(), {});
            return;
        }
        if (m_busy) {
            // uninstall / purge finished
            setBusy(false);
            const QString tail = m_operationOutput.section(QLatin1Char('\n'), -3)
                                     .trimmed();
            if (success) {
                ActivityLog::instance()->add(
                    QStringLiteral("Package operation finished"),
                    tail.isEmpty() ? QStringLiteral("exit code 0") : tail);
                emit uninstallFinished(true, QStringLiteral("Package removed successfully"));
                refresh(); // list is stale after removal — refresh immediately
            } else if (exitCode == 126 || exitCode == 127) {
                emit uninstallFinished(
                    false,
                    QStringLiteral(
                        "Authorization was cancelled or denied. Package not removed."));
            } else {
                emit uninstallFinished(
                    false,
                    QStringLiteral("Package removal failed (exit code %1). %2")
                        .arg(exitCode)
                        .arg(tail));
            }
        }
    });
}

void PackageService::setLoading(bool value)
{
    if (value == m_loading)
        return;
    m_loading = value;
    emit loadingChanged();
}

void PackageService::setBusy(bool value)
{
    if (value == m_busy)
        return;
    m_busy = value;
    emit busyChanged();
}

void PackageService::setLastError(const QString &message)
{
    if (message == m_lastError)
        return;
    m_lastError = message;
    emit lastErrorChanged();
}

void PackageService::appendOperationOutput(const QString &text)
{
    m_operationOutput += text;
    // Keep a rolling tail so very long operations cannot grow memory.
    const int maxChars = 16 * 1024;
    if (m_operationOutput.size() > maxChars)
        m_operationOutput = m_operationOutput.mid(m_operationOutput.size() - maxChars);
    emit operationOutputChanged();
}

void PackageService::refresh()
{
    if (m_loading || m_busy)
        return;

    setLoading(true);
    m_operationOutput.clear();
    emit operationOutputChanged();

    m_process.start(QStringLiteral("dpkg-query"),
                    { QStringLiteral("-W"),
                      QStringLiteral("-f"), QString::fromLatin1(kDpkgQueryFormat) });
}

bool PackageService::uninstall(const QString &packageName, bool purge)
{
    if (m_busy || m_loading)
        return false;

    if (!isValidPackageName(packageName)) {
        emit uninstallFinished(
            false, QStringLiteral("'%1' is not a valid package name").arg(packageName));
        return false;
    }

    setBusy(true);
    setLastError({});
    m_operationOutput.clear();
    emit operationOutputChanged();
    appendOperationOutput(QStringLiteral(
        "Removing %1 with the system package manager...\n").arg(packageName));

    // pkexec resets the environment, so DEBIAN_FRONTEND must travel via `env`.
    // Arguments stay separate; no shell string is constructed (MM-082).
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("DEBIAN_FRONTEND"), QStringLiteral("noninteractive"));

    QStringList arguments;
    arguments << QStringLiteral("env")
              << QStringLiteral("DEBIAN_FRONTEND=noninteractive")
              << QStringLiteral("apt-get")
              << (purge ? QStringLiteral("purge") : QStringLiteral("remove"))
              << QStringLiteral("-y")
              << packageName;
    m_process.start(QStringLiteral("pkexec"), arguments, env);
    return true;
}

QVector<PackageEntry> PackageService::parseDpkgQueryOutput(const QString &output)
{
    QVector<PackageEntry> entries;

    const QStringList lines = output.split(QLatin1Char('\n'));
    for (const QString &line : lines) {
        if (line.trimmed().isEmpty())
            continue;

        const QStringList fields = line.split(QLatin1Char('\t'));
        // Package, Status, Version, Architecture, Installed-Size, Section, Summary
        if (fields.size() < 7)
            continue; // malformed record — skip, never abort the whole list

        if (fields.at(1).trimmed() != QLatin1String("installed"))
            continue;

        PackageEntry entry;
        entry.name = fields.at(0).trimmed();
        entry.version = fields.at(2).trimmed();
        entry.architecture = fields.at(3).trimmed();

        bool ok = false;
        const quint64 kib = fields.at(4).trimmed().toULongLong(&ok);
        entry.installedSizeBytes = ok ? SizeUtils::kibToBytes(kib) : 0;

        entry.section = fields.at(5).trimmed();
        entry.summary = fields.mid(6).join(QLatin1Char('\t')).trimmed();

        if (entry.name.isEmpty())
            continue;
        entries.append(entry);
    }

    return entries;
}
