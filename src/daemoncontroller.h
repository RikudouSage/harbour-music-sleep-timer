#ifndef DAEMONCONTROLLER_H
#define DAEMONCONTROLLER_H

#include <QByteArray>
#include <QObject>
#include <QString>
#include <QVariant>

#ifdef MUSIC_SLEEP_TIMER_USE_SOCKET
#include <QJsonObject>
#include <QLocalSocket>
#include <QQueue>
#include <QStringList>
#endif

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
#ifdef MUSIC_SLEEP_TIMER_USE_SOCKET
    enum PendingCommand {
        PendingVoid,
        PendingHasTimer,
        PendingGetTimer,
    };

    void ensureSocketConnected();
    void sendSocketCommand(const QString &command, PendingCommand pendingCommand);
    void flushSocketCommands();
    void handleSocketLine(const QByteArray &line);
    void handleSocketEvent(const QString &event);
    void handleSocketResponse(const QJsonObject &response);
    void handleSocketErrorResponse(const QJsonObject &response);
    QString socketPath() const;

    QLocalSocket *m_socket = nullptr;
    QByteArray m_socketBuffer;
    QStringList m_queuedSocketCommands;
    QQueue<PendingCommand> m_pendingSocketCommands;
#else
    void callVoidMethod(const QString &method, const QVariantList &arguments = QVariantList());
    void connectDaemonSignal(const QString &signal, const char *slot);
#endif

private slots:
#ifdef MUSIC_SLEEP_TIMER_USE_SOCKET
    void handleSocketConnected();
    void handleSocketReadyRead();
    void handleSocketError();
#endif
    void handleTimerFired();
    void handleTimerRemoved();
    void handleTimerConfigured();
};

#endif // DAEMONCONTROLLER_H
