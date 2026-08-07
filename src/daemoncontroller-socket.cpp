#include "daemoncontroller.h"

#ifdef MUSIC_SLEEP_TIMER_USE_SOCKET

DaemonController::DaemonController(QObject *parent) : QObject(parent)
{
    // todo implement socket controller
}

void DaemonController::createTimer(qint64 fireInSeconds, bool waitForTrackFinish, qint64 maxWaitSeconds)
{
    Q_UNUSED(fireInSeconds)
    Q_UNUSED(waitForTrackFinish)
    Q_UNUSED(maxWaitSeconds)
    // todo implement socket controller
}

void DaemonController::cancelTimer()
{
    // todo implement socket controller
}

void DaemonController::hasTimer()
{
    // todo implement socket controller
}

void DaemonController::getTimer()
{
    // todo implement socket controller
}

void DaemonController::callVoidMethod(const QString &method, const QVariantList &arguments)
{
    Q_UNUSED(method)
    Q_UNUSED(arguments)
    // todo implement socket controller
}

void DaemonController::connectDaemonSignal(const QString &signal, const char *slot)
{
    Q_UNUSED(signal)
    Q_UNUSED(slot)
    // todo implement socket controller
}

void DaemonController::handleTimerFired()
{
    // todo implement socket controller
}

void DaemonController::handleTimerRemoved()
{
    // todo implement socket controller
}

void DaemonController::handleTimerConfigured()
{
    // todo implement socket controller
}

#endif
