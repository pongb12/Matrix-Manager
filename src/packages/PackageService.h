/*
 * PackageService.h — installed .deb package enumeration and safe removal
 * (MM-040, MM-042, MM-043).
 *
 * Safety rules implemented (AGENT.md rule 10, DOC.md rules 12-13):
 *   - enumeration uses `dpkg-query` only (read-only, no lock contention)
 *   - removal uses `apt-get` through `pkexec`; the GUI stays unprivileged
 *   - package names are validated before being passed to any process
 *   - program and arguments are always separate (no shell strings)
 */
#pragma once

#include <QObject>
#include <QRegularExpression>
#include <QStringList>
#include <QVector>

#include "PackageModel.h"
#include "platform/linux/ProcessRunner.h"

class PackageService : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)
    Q_PROPERTY(PackageModel *model READ model CONSTANT)
    Q_PROPERTY(QString operationOutput READ operationOutput NOTIFY operationOutputChanged)

public:
    static PackageService *instance();

    PackageModel *model() const { return m_model; }
    bool loading() const { return m_loading; }
    bool busy() const { return m_busy; }
    QString lastError() const { return m_lastError; }
    QString operationOutput() const { return m_operationOutput; }

    // Enumerate installed packages via dpkg-query (asynchronous).
    Q_INVOKABLE void refresh();

    // Remove a package with apt-get through pkexec (asynchronous).
    // The package name is validated; invalid names are rejected.
    Q_INVOKABLE bool uninstall(const QString &packageName, bool purge = false);

    // Pure parsing helper, exposed for unit tests (MM-110).
    static QVector<PackageEntry> parseDpkgQueryOutput(const QString &output);

    // Validation helper, exposed for unit tests.
    static bool isValidPackageName(const QString &name);

signals:
    void loadingChanged();
    void busyChanged();
    void lastErrorChanged();
    void operationOutputChanged();
    void refreshFinished(bool success, int count, const QString &error);
    void uninstallFinished(bool success, const QString &message);

private:
    explicit PackageService(QObject *parent = nullptr);

    void setLoading(bool value);
    void setBusy(bool value);
    void setLastError(const QString &message);
    void appendOperationOutput(const QString &text);

    PackageModel *m_model = nullptr;
    AsyncProcess m_process;
    bool m_loading = false;
    bool m_busy = false;
    QString m_lastError;
    QString m_operationOutput;

    static const QRegularExpression &packageNameRegex();
};
