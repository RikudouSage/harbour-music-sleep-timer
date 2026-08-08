#ifndef DAEMONINSTALLER_H
#define DAEMONINSTALLER_H

#include <QObject>
#include <QString>

class DaemonInstaller : public QObject
{
    Q_OBJECT
public:
    enum DaemonStatus {
        DaemonStatusRunning,
        DaemonStatusInstalled,
        DaemonStatusNone,
    };
    Q_ENUM(DaemonStatus);

    explicit DaemonInstaller(QObject *parent = nullptr);

    Q_INVOKABLE void checkDaemonStatus();
    Q_INVOKABLE void installDaemon();
    Q_INVOKABLE void startDaemon();

signals:
    void installStatusResolved(DaemonStatus status);
    void installFinished(bool success);
    void daemonStartFinished(bool success);

private:
    DaemonStatus systemdDaemonStatus() const;
    QString daemonRpmPath() const;

    const QString rpmsPath;

private slots:
    void handleInstallFinished(bool success, const QString &errorString);
    void requestDaemonInstall(const QString &rpmPath);
};

Q_DECLARE_METATYPE(DaemonInstaller::DaemonStatus)

#endif // DAEMONINSTALLER_H
