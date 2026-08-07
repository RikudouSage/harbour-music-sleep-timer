#include "daemoncontroller.h"

#ifdef MUSIC_SLEEP_TIMER_USE_SOCKET

#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonParseError>
#include <QLocalSocket>
#include <QStandardPaths>

namespace {

constexpr auto SOCKET_DIR_NAME = "cz.chrastecky";
constexpr auto SOCKET_APP_NAME = "music-sleep-timer";
constexpr auto SOCKET_NAME = "music-sleep-timer.sock";

QString socketErrorMessage(const QJsonObject &error)
{
    const auto name = error.value("name").toString();
    const auto message = error.value("message").toString();

    if (message.isEmpty()) {
        return name;
    }

    return QStringLiteral("%1: %2").arg(name, message);
}

}

DaemonController::DaemonController(QObject *parent) : QObject(parent),
    m_socket(new QLocalSocket(this))
{
    connect(m_socket, &QLocalSocket::connected, this, &DaemonController::handleSocketConnected);
    connect(m_socket, &QLocalSocket::readyRead, this, &DaemonController::handleSocketReadyRead);
    connect(m_socket, static_cast<void (QLocalSocket::*)(QLocalSocket::LocalSocketError)>(&QLocalSocket::error), this, &DaemonController::handleSocketError);
    ensureSocketConnected();
}

void DaemonController::createTimer(qint64 fireInSeconds, bool waitForTrackFinish, qint64 maxWaitSeconds)
{
    sendSocketCommand(
        QStringLiteral("create %1 %2 %3")
            .arg(fireInSeconds)
            .arg(waitForTrackFinish ? "true" : "false")
            .arg(maxWaitSeconds),
        PendingVoid
    );
}

void DaemonController::cancelTimer()
{
    sendSocketCommand("cancel", PendingVoid);
}

void DaemonController::hasTimer()
{
    sendSocketCommand("has", PendingHasTimer);
}

void DaemonController::getTimer()
{
    sendSocketCommand("get", PendingGetTimer);
}

void DaemonController::ensureSocketConnected()
{
    if (m_socket->state() == QLocalSocket::ConnectedState || m_socket->state() == QLocalSocket::ConnectingState) {
        return;
    }

    m_socket->connectToServer(socketPath());
}

void DaemonController::sendSocketCommand(const QString &command, PendingCommand pendingCommand)
{
    m_pendingSocketCommands.enqueue(pendingCommand);

    if (m_socket->state() == QLocalSocket::ConnectedState) {
        m_socket->write(command.toUtf8() + '\n');
        return;
    }

    m_queuedSocketCommands.append(command);
    ensureSocketConnected();
}

void DaemonController::flushSocketCommands()
{
    for (const auto &command : m_queuedSocketCommands) {
        m_socket->write(command.toUtf8() + '\n');
    }
    m_queuedSocketCommands.clear();
}

void DaemonController::handleSocketLine(const QByteArray &line)
{
    QJsonParseError parseError;
    const auto document = QJsonDocument::fromJson(line, &parseError);
    if (parseError.error != QJsonParseError::NoError || !document.isObject()) {
        emit error(QStringLiteral("Invalid socket response: %1").arg(parseError.errorString()));
        return;
    }

    const auto object = document.object();
    if (object.contains("event")) {
        handleSocketEvent(object.value("event").toString());
        return;
    }

    if (object.contains("ok")) {
        handleSocketResponse(object);
        return;
    }

    emit error("Unexpected socket message: " + line);
}

void DaemonController::handleSocketEvent(const QString &event)
{
    if (event == "TimerFired") {
        handleTimerFired();
    } else if (event == "TimerRemoved") {
        handleTimerRemoved();
    } else if (event == "TimerConfigured") {
        handleTimerConfigured();
    }
}

void DaemonController::handleSocketResponse(const QJsonObject &response)
{
    const auto pendingCommand = m_pendingSocketCommands.isEmpty() ? PendingVoid : m_pendingSocketCommands.dequeue();

    if (!response.value("ok").toBool()) {
        handleSocketErrorResponse(response);
        return;
    }

    const auto result = response.value("result");
    switch (pendingCommand) {
    case PendingVoid:
        return;
    case PendingHasTimer:
        emit hasTimerReceived(result.toBool());
        return;
    case PendingGetTimer: {
        const auto timer = result.toObject();
        emit timerReceived(
            timer.value("exists").toBool(),
            static_cast<qint64>(timer.value("fireAtUnix").toDouble()),
            static_cast<qint64>(timer.value("createdAtUnix").toDouble()),
            timer.value("waitForTrackFinish").toBool(),
            static_cast<qint64>(timer.value("maxWaitSeconds").toDouble())
        );
        return;
    }
    }
}

void DaemonController::handleSocketErrorResponse(const QJsonObject &response)
{
    const auto errorValue = response.value("error");
    if (errorValue.isObject()) {
        emit error(socketErrorMessage(errorValue.toObject()));
    } else {
        emit error("Socket command failed");
    }
}

QString DaemonController::socketPath() const
{
    const auto configPath = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation);
    if (!configPath.isEmpty()) {
        return QStringLiteral("%1/%2/%3/%4")
            .arg(
                configPath,
                SOCKET_DIR_NAME,
                SOCKET_APP_NAME,
                SOCKET_NAME
            );
    }

    return QStringLiteral("/tmp/%1/%2/%3")
        .arg(
            QString::fromLatin1(SOCKET_DIR_NAME),
            QString::fromLatin1(SOCKET_APP_NAME),
            QString::fromLatin1(SOCKET_NAME)
        );
}

void DaemonController::handleSocketConnected()
{
    flushSocketCommands();
}

void DaemonController::handleSocketReadyRead()
{
    m_socketBuffer.append(m_socket->readAll());

    int newlineIndex = m_socketBuffer.indexOf('\n');
    while (newlineIndex >= 0) {
        const auto line = m_socketBuffer.left(newlineIndex).trimmed();
        m_socketBuffer.remove(0, newlineIndex + 1);
        if (!line.isEmpty()) {
            handleSocketLine(line);
        }
        newlineIndex = m_socketBuffer.indexOf('\n');
    }
}

void DaemonController::handleSocketError()
{
    emit error(m_socket->errorString());
}

void DaemonController::handleTimerFired()
{
    emit timerFired();
}

void DaemonController::handleTimerRemoved()
{
    emit timerRemoved();
}

void DaemonController::handleTimerConfigured()
{
    emit timerConfigured();
}

#endif
