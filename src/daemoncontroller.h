#ifndef DAEMONCONTROLLER_H
#define DAEMONCONTROLLER_H

#include <QObject>
#include <QString>
#include <QVariant>

class DaemonController : public QObject
{
    Q_OBJECT
public:
    explicit DaemonController(QObject *parent = nullptr);

    Q_INVOKABLE void createTimer(qint64 fireInSeconds, bool waitForTrackFinish, qint64 maxWaitSeconds);
    Q_INVOKABLE void cancelTimer();
    Q_INVOKABLE void hasTimer();
    Q_INVOKABLE void getTimer();

signals:
    void timerFired();
    void timerRemoved();
    void timerConfigured();
    void hasTimerReceived(bool hasTimer);
    void timerReceived(bool exists, qint64 fireAtUnix, qint64 createdAtUnix, bool waitForTrackFinish, qint64 maxWaitSeconds);
    void error(const QString &message);

private:
    void callVoidMethod(const QString &method, const QVariantList &arguments = QVariantList());
    void connectDaemonSignal(const QString &signal, const char *slot);

private slots:
    void handleTimerFired();
    void handleTimerRemoved();
    void handleTimerConfigured();
};

#endif // DAEMONCONTROLLER_H
