#include "daemoncontroller.h"

#ifndef MUSIC_SLEEP_TIMER_USE_SOCKET

#include <QDBusArgument>
#include <QDBusConnection>
#include <QDBusError>
#include <QDBusInterface>
#include <QDBusMessage>
#include <QDBusMetaType>
#include <QDBusReply>
#include <QVariant>

struct DBusTimerConfig
{
    bool exists = false;
    qint64 fireAtUnix = 0;
    qint64 createdAtUnix = 0;
    bool waitForTrackFinish = false;
    qint64 maxWaitSeconds = 0;
};

Q_DECLARE_METATYPE(DBusTimerConfig)

QDBusArgument &operator<<(QDBusArgument &argument, const DBusTimerConfig &config)
{
    argument.beginStructure();
    argument << config.exists
             << config.fireAtUnix
             << config.createdAtUnix
             << config.waitForTrackFinish
             << config.maxWaitSeconds;
    argument.endStructure();

    return argument;
}

const QDBusArgument &operator>>(const QDBusArgument &argument, DBusTimerConfig &config)
{
    argument.beginStructure();
    argument >> config.exists
             >> config.fireAtUnix
             >> config.createdAtUnix
             >> config.waitForTrackFinish
             >> config.maxWaitSeconds;
    argument.endStructure();

    return argument;
}

namespace {

constexpr auto DBUS_SERVICE = "dev.rikudousage.MusicStopDaemon";
constexpr auto DBUS_PATH = "/dev/rikudousage/MusicStopDaemon";
constexpr auto DBUS_INTERFACE = "dev.rikudousage.MusicStopDaemon.Controller";

QDBusInterface createInterface()
{
    return QDBusInterface(
        DBUS_SERVICE,
        DBUS_PATH,
        DBUS_INTERFACE,
        QDBusConnection::sessionBus()
    );
}

QString errorMessage(const QDBusError &error)
{
    if (error.message().isEmpty()) {
        return error.name();
    }

    return QStringLiteral("%1: %2").arg(error.name(), error.message());
}

QString errorMessage(const QDBusMessage &message)
{
    if (message.errorMessage().isEmpty()) {
        return message.errorName();
    }

    return QStringLiteral("%1: %2").arg(message.errorName(), message.errorMessage());
}

}

DaemonController::DaemonController(QObject *parent) : QObject(parent)
{
    qDBusRegisterMetaType<DBusTimerConfig>();

    connectDaemonSignal("TimerFired", SLOT(handleTimerFired()));
    connectDaemonSignal("TimerRemoved", SLOT(handleTimerRemoved()));
    connectDaemonSignal("TimerConfigured", SLOT(handleTimerConfigured()));
}

void DaemonController::createTimer(qint64 fireInSeconds, bool waitForTrackFinish, qint64 maxWaitSeconds)
{
    callVoidMethod("CreateTimer", QVariantList{
        QVariant::fromValue(fireInSeconds),
        QVariant::fromValue(waitForTrackFinish),
        QVariant::fromValue(maxWaitSeconds),
    });
}

void DaemonController::cancelTimer()
{
    callVoidMethod("CancelTimer");
}

void DaemonController::hasTimer()
{
    auto iface = createInterface();
    const QDBusReply<bool> reply = iface.call("HasTimer");
    if (!reply.isValid()) {
        emit error(errorMessage(reply.error()));
        return;
    }

    emit hasTimerReceived(reply.value());
}

void DaemonController::getTimer()
{
    auto iface = createInterface();
    const QDBusReply<DBusTimerConfig> reply = iface.call("GetTimer");
    if (!reply.isValid()) {
        emit error(errorMessage(reply.error()));
        return;
    }

    const auto config = reply.value();
    emit timerReceived(config.exists, config.fireAtUnix, config.createdAtUnix, config.waitForTrackFinish, config.maxWaitSeconds);
}

void DaemonController::callVoidMethod(const QString &method, const QVariantList &arguments)
{
    auto iface = createInterface();
    const QDBusMessage reply = iface.callWithArgumentList(QDBus::Block, method, arguments);
    if (reply.type() == QDBusMessage::ErrorMessage) {
        emit error(errorMessage(reply));
    }
}

void DaemonController::connectDaemonSignal(const QString &signal, const char *slot)
{
    const auto connected = QDBusConnection::sessionBus().connect(
        DBUS_SERVICE,
        DBUS_PATH,
        DBUS_INTERFACE,
        signal,
        this,
        slot
    );
    if (!connected) {
        emit error(QStringLiteral("Failed to connect D-Bus signal %1").arg(signal));
    }
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
