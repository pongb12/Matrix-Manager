/*
 * ProcessRunner.h — safe process execution for Linux system integration.
 *
 * DOC.md rule 13 / TASK.md MM-082:
 *   - never build shell strings; program and arguments stay separate
 *   - capture stdout/stderr for reporting
 *   - timeouts where appropriate
 *   - clear, typed error reporting
 */
#pragma once

#include <QObject>
#include <QProcess>
#include <QProcessEnvironment>
#include <QString>
#include <QStringList>

namespace ProcessRunner
{
struct Result
{
    bool started = false;     // process could be started at all
    int exitCode = -1;
    bool timedOut = false;
    QString standardOutput;
    QString standardError;

    bool success() const { return started && exitCode == 0 && !timedOut; }
};

// Synchronous execution. Only use for short-lived queries (e.g. version
// checks). Long operations must use AsyncProcess below.
Result run(const QString &program, const QStringList &arguments,
           int timeoutMs = 30000);
} // namespace ProcessRunner

/*
 * Asynchronous process wrapper with progress output. Used for package
 * operations and privileged cleanups that may run for a while.
 *
 * Kept outside the namespace on purpose: moc-generated code for QObject
 * subclasses inside namespaces is fragile across Qt versions.
 */
class AsyncProcess : public QObject
{
    Q_OBJECT
public:
    explicit AsyncProcess(QObject *parent = nullptr);
    ~AsyncProcess() override;

    void start(const QString &program, const QStringList &arguments,
               const QProcessEnvironment &environment
                   = QProcessEnvironment::systemEnvironment());

    // Kill the running process. Only used when the operation is safely
    // interruptible; destructive package operations are NOT cancellable.
    void kill();

    bool isRunning() const;

signals:
    void outputChunk(const QString &text);
    void finished(bool success, int exitCode, const QString &output);

private:
    QProcess *m_process = nullptr;
    // Full output accumulated across readyRead chunks. QProcess::readAll()
    // at process end returns only what was NOT consumed earlier — for large
    // outputs (dpkg-query lists every installed package) the readyRead
    // handler already drained the pipe, so the finished signal previously
    // delivered an (almost) empty output. Accumulate and decode once.
    QByteArray m_rawOutput;
};
