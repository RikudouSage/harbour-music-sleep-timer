#include "daemoninstaller.h"

#include <QDBusInterface>
#include <QDBusObjectPath>
#include <QDBusPendingCall>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>
#include <QDBusReply>
#include <QDir>
#include <QUrl>
#include <QtConcurrent>

#include "sailfishapp.h"

namespace {

constexpr auto SYSTEMD_SERVICE = "org.freedesktop.systemd1";
constexpr auto SYSTEMD_PATH = "/org/freedesktop/systemd1";
constexpr auto SYSTEMD_MANAGER_INTERFACE = "org.freedesktop.systemd1.Manager";
constexpr auto SYSTEMD_UNIT_INTERFACE = "org.freedesktop.systemd1.Unit";
constexpr auto DAEMON_SERVICE_NAME = "harbour-music-sleep-timer-daemon.service";
constexpr auto INSTALLATION_HANDLER_SERVICE = "org.sailfishos.installationhandler";
constexpr auto INSTALLATION_HANDLER_PATH = "/org/sailfishos/installationhandler";
constexpr auto INSTALLATION_HANDLER_INTERFACE = "org.sailfishos.installationhandler";

}

DaemonInstaller::DaemonInstaller(QObject *parent)
    : QObject(parent), rpmsPath(SailfishApp::pathTo("daemon-rpms").toLocalFile())
{
    qRegisterMetaType<DaemonStatus>("DaemonStatus");
    qRegisterMetaType<DaemonStatus>("DaemonInstaller::DaemonStatus");

    QDBusConnection::sessionBus().connect(
        INSTALLATION_HANDLER_SERVICE,
        INSTALLATION_HANDLER_PATH,
        INSTALLATION_HANDLER_INTERFACE,
        "installFinished",
        this,
        SLOT(handleInstallFinished(bool, QString))
    );
}

void DaemonInstaller::checkDaemonStatus()
{
    QtConcurrent::run([=] {
        emit installStatusResolved(systemdDaemonStatus());
    });
}

void DaemonInstaller::installDaemon()
{
    QtConcurrent::run([=] {
        const auto rpmPath = daemonRpmPath();
        QMetaObject::invokeMethod(
            this,
            "requestDaemonInstall",
            Qt::QueuedConnection,
            Q_ARG(QString, rpmPath)
        );
    });
}

void DaemonInstaller::startDaemon()
{
    QDBusInterface systemd(
        SYSTEMD_SERVICE,
        SYSTEMD_PATH,
        SYSTEMD_MANAGER_INTERFACE,
        QDBusConnection::sessionBus()
    );
    auto *watcher = new QDBusPendingCallWatcher(
        systemd.asyncCall("StartUnit", DAEMON_SERVICE_NAME, "replace"),
        this
    );
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this](QDBusPendingCallWatcher *watcher) {
        const QDBusPendingReply<QDBusObjectPath> reply = *watcher;
        if (reply.isError()) {
            qWarning() << reply.error().message();
            emit daemonStartFinished(false);
        } else {
            emit daemonStartFinished(true);
        }
        watcher->deleteLater();
    });
}

DaemonInstaller::DaemonStatus DaemonInstaller::systemdDaemonStatus() const
{
    QDBusInterface systemd(
        SYSTEMD_SERVICE,
        SYSTEMD_PATH,
        SYSTEMD_MANAGER_INTERFACE,
        QDBusConnection::sessionBus()
    );
    QDBusReply<QDBusObjectPath> unitReply = systemd.call("GetUnit", DAEMON_SERVICE_NAME);
    if (!unitReply.isValid()) {
        unitReply = systemd.call("LoadUnit", DAEMON_SERVICE_NAME);
    }
    if (!unitReply.isValid()) {
        return DaemonStatusNone;
    }

    QDBusInterface unit(
        SYSTEMD_SERVICE,
        unitReply.value().path(),
        "org.freedesktop.DBus.Properties",
        QDBusConnection::sessionBus()
    );
    const QDBusReply<QVariant> activeStateReply = unit.call("Get", SYSTEMD_UNIT_INTERFACE, "ActiveState");
    if (!activeStateReply.isValid()) {
        return DaemonStatusInstalled;
    }

    if (activeStateReply.value().toString() == "active") {
        return DaemonStatusRunning;
    }

    return DaemonStatusInstalled;
}

QString DaemonInstaller::daemonRpmPath() const
{
    const QDir rpmsDir(rpmsPath);
    const auto rpmFiles = rpmsDir.entryInfoList(QStringList{"harbour*.rpm"}, QDir::Files, QDir::Name);
    if (rpmFiles.isEmpty()) {
        return {};
    }

    return rpmFiles.first().absoluteFilePath();
}

void DaemonInstaller::requestDaemonInstall(const QString &rpmPath)
{
    if (rpmPath.isEmpty()) {
        qWarning() << "The rpm path is empty, the bundled rpm is missing";
        emit installFinished(false);
        return;
    }

    QDBusInterface installationHandler(
        INSTALLATION_HANDLER_SERVICE,
        INSTALLATION_HANDLER_PATH,
        INSTALLATION_HANDLER_INTERFACE,
        QDBusConnection::sessionBus()
    );
    const auto fileUrls = QStringList{QUrl::fromLocalFile(rpmPath).toString()};
    auto *watcher = new QDBusPendingCallWatcher(
        installationHandler.asyncCall("installFiles", fileUrls),
        this
    );
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this](QDBusPendingCallWatcher *watcher) {
        const QDBusPendingReply<> reply = *watcher;
        if (reply.isError()) {
            emit installFinished(false);
        }
        watcher->deleteLater();
    });
}

void DaemonInstaller::handleInstallFinished(bool success, const QString &errorString)
{
    if (!success && !errorString.isEmpty()) {
        qWarning() << errorString;
    }

    emit installFinished(success);
}
