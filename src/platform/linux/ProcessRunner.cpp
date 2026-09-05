#include "ProcessRunner.h"

#include <QTimer>

namespace ProcessRunner
{
Result run(const QString &program, const QStringList &arguments, int timeoutMs)
{
    Result result;
    QProcess process;

    result.started = true;
    process.start(program, arguments);
    if (!process.waitForStarted(5000)) {
        result.started = false;
        result.standardError = process.errorString();
        return result;
    }

    if (!process.waitForFinished(timeoutMs)) {
        if (process.state() != QProcess::NotRunning) {
            process.kill();
            process.waitForFinished(3000);
        }
        result.timedOut = true;
        result.standardError = QStringLiteral("Process timed out after %1 ms")
                                   .arg(timeoutMs);
        return result;
    }

    result.exitCode = process.exitCode();
    result.standardOutput = QString::fromLocal8Bit(process.readAllStandardOutput());
    result.standardError = QString::fromLocal8Bit(process.readAllStandardError());
    return result;
}

} // namespace ProcessRunner

AsyncProcess::AsyncProcess(QObject *parent)
    : QObject(parent)
{
}

AsyncProcess::~AsyncProcess()
{
    if (m_process && m_process->state() != QProcess::NotRunning) {
        // If the parent object is destroyed while a process is running,
        // terminate it instead of leaving an orphan behind.
        m_process->kill();
        m_process->waitForFinished(2000);
    }
}

void AsyncProcess::start(const QString &program, const QStringList &arguments,
                         const QProcessEnvironment &environment)
{
    if (m_process) { // one process at a time per wrapper
        qWarning("AsyncProcess::start called while already running");
        return;
    }

    m_process = new QProcess(this);
    m_process->setProcessEnvironment(environment);
    m_process->setProcessChannelMode(QProcess::MergedChannels);
    m_rawOutput.clear();

    connect(m_process, &QProcess::readyReadStandardOutput, this, [this] {
        const QByteArray bytes = m_process->readAllStandardOutput();
        if (!bytes.isEmpty()) {
            m_rawOutput += bytes;
            emit outputChunk(QString::fromLocal8Bit(bytes));
        }
    });

    connect(m_process, &QProcess::errorOccurred, this,
            [this](QProcess::ProcessError error) {
        Q_UNUSED(error)
        emit outputChunk(QStringLiteral("[error] %1\n")
                             .arg(m_process->errorString()));
    });

    connect(m_process, &QProcess::finished, this,
            [this](int exitCode, QProcess::ExitStatus status) {
        // Anything that arrived after the last readyRead is still buffered;
        // merge it into the accumulated output, then decode exactly once so
        // multi-byte UTF-8 sequences split across chunk boundaries survive.
        m_rawOutput += m_process->readAll();
        const QString output = QString::fromLocal8Bit(m_rawOutput);
        const bool ok = status == QProcess::NormalExit && exitCode == 0;
        QProcess *proc = m_process;
        m_process = nullptr;
        proc->deleteLater();
        emit finished(ok, exitCode, output);
    });

    m_process->start(program, arguments);
    if (!m_process->waitForStarted(5000)) {
        const QString error = m_process->errorString();
        m_process->deleteLater();
        m_process = nullptr;
        emit outputChunk(QStringLiteral("[error] Could not start %1: %2\n")
                             .arg(program, error));
        emit finished(false, -1, error);
    }
}

void AsyncProcess::kill()
{
    if (m_process && m_process->state() != QProcess::NotRunning)
        m_process->kill();
}

bool AsyncProcess::isRunning() const
{
    return m_process && m_process->state() != QProcess::NotRunning;
}
