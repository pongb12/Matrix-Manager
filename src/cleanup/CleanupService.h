/*
 * CleanupService.h — explicit, rule-based cleanup (MM-050 .. MM-054).
 *
 * Every cleanup rule is deterministic and carries an explicit reason.
 * This service never classifies arbitrary user files as junk, never applies
 * age-based heuristics and never deletes anything without the user asking
 * for it in the UI. See DOC.md rules 9-10 for the product safety contract.
 *
 * MVP rules:
 *   - user-trash      : XDG home trash (LOW risk, no privilege)
 *   - apt-cache       : downloaded .deb archives via `apt-get clean`
 *                       (LOW risk, requires authorization through pkexec)
 *   - thumbnail-cache : freedesktop thumbnail cache, regenerated on demand
 *                       (MEDIUM risk, no privilege)
 */
#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QVector>
#include <QVariantMap>

class CleanupService : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool running READ running NOTIFY runningChanged)

public:
    enum RiskLevel
    {
        LowRisk = 0,
        MediumRisk = 1,
        HighRisk = 2
    };
    Q_ENUM(RiskLevel)

    struct CleanupRule
    {
        QString id;
        QString name;
        QString description;
        QString consequence;   // what exactly happens when cleaned
        QStringList targets;   // human-readable target paths
        RiskLevel risk = LowRisk;
        bool requiresPrivilege = false;
    };

    static CleanupService *instance();

    bool running() const { return m_running; }

    // List of rules as QVariantMap for QML:
    //   id, name, description, consequence, targets (QStringList),
    //   risk ("LOW"/"MEDIUM"/"HIGH"), riskLevel (int), requiresPrivilege
    Q_INVOKABLE QVariantList rules() const;

    // Estimate a rule's reclaimable size: { bytes, itemCount, error }.
    Q_INVOKABLE QVariantMap estimate(const QString &ruleId);

    // Run the selected rules sequentially. Privileged rules request
    // authorization at the operation boundary through pkexec.
    Q_INVOKABLE void clean(const QStringList &ruleIds);

    // Stop after the currently running rule completes.
    Q_INVOKABLE void stopAfterCurrent();

    // Static helpers exposed for unit tests (MM-110).
    static bool isSafeSubPath(const QString &canonicalRoot,
                              const QString &candidatePath);
    static QString trashRootPath();

signals:
    void runningChanged();
    void ruleStarted(const QString &ruleId);
    void ruleFinished(const QString &ruleId, bool success, quint64 freedBytes,
                      const QString &error);
    void allFinished();

private:
    explicit CleanupService(QObject *parent = nullptr);

    const CleanupRule *ruleById(const QString &id) const;
    void runNextRule();

    QVariantMap estimateTrash();
    QVariantMap estimateAptCache();
    QVariantMap estimateThumbnails();

    bool emptyTrash(quint64 *freedBytes, QString *error);
    bool cleanAptCache(quint64 *freedBytes, QString *error);
    bool cleanThumbnails(quint64 *freedBytes, QString *error);

    // Removes one top-level trash/thumbnail entry (file or directory tree)
    // after strict prefix validation. Returns bytes freed.
    quint64 removeEntry(const QString &entryPath, bool *ok);

    QVector<CleanupRule> m_rules;
    bool m_running = false;
    bool m_stopRequested = false;
    QStringList m_pendingRules;
    quint64 m_currentFreed = 0;
};
