import QtQuick 2.0
import Sailfish.Silica 1.0

import dev.chrastecky 1.0

Page {
    property string errorText
    property bool loading: errorText === '' && !needsInstall
    property var doWhenReady: []
    property bool needsInstall: false

    function safeCall(callable) {
        if (!pageStack.busy) {
            callable();
            return;
        }

        doWhenReady.push(callable);
    }

    id: page

    DaemonInstaller {
        id: installer

        onInstallStatusResolved: {
            if (status === DaemonInstaller.DaemonStatusRunning) {
                safeCall(function() {
                    pageStack.replace("TimerPage.qml");
                });
                return;
            }
            if (status === DaemonInstaller.DaemonStatusNone) {
                needsInstall = true;
                return;
            }
            if (status === DaemonInstaller.DaemonStatusInstalled) {
                //% "Enabling daemon..."
                loader.text = qsTrId("check_daemon.enabling");
                installer.startDaemon();
                return;
            }

            //% "Daemon status check returned unknown status: %1"
            errorText = qsTrId("daemon_check.unknown_status").arg(status);
        }

        onInstallFinished: {
            if (!success) {
                //% "Installation of the daemon failed, cannot continue."
                errorText = qsTrId("check_daemon.install_failed")
                return;
            }

            installer.checkDaemonStatus();
        }

        onDaemonStartFinished: {
            if (!success) {
                //% "Failed starting the daemon, the app cannot continue."
                errorText = qsTrId("check_daemon.start_failed");
                return;
            }

            installer.checkDaemonStatus();
        }
    }

    Connections {
        target: pageStack

        onBusyChanged: {
            var callable;
            // @disable-check M19
            while (callable = doWhenReady.pop()) {
                callable();
            }
        }
    }

    Component.onCompleted: {
        installer.checkDaemonStatus();
    }

    BusyLabel {
        id: loader
        running: loading
        //% "Loading..."
        text: qsTrId("check_daemon.loading")
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                //% "Checking daemon"
                title: qsTrId("check_daemon.title")
            }

            Label {
                text: errorText
                x: Theme.paddingLarge
                width: parent.width - Theme.paddingLarge * 2
                color: Theme.errorColor
                wrapMode: Text.Wrap
                visible: errorText !== ''
            }

            Label {
                //% "For this app to work, a background daemon needs to be installed - this daemon actually controls the music and this app exists to control the daemon"
                text: qsTrId("check_daemon.install_daemon.description")
                x: Theme.paddingLarge
                width: parent.width - Theme.paddingLarge * 2
                wrapMode: Text.Wrap
                visible: errorText === '' && needsInstall
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                //% "Install daemon"
                text: qsTrId("check_daemon.install_daemon.install")
                visible: errorText === '' && needsInstall
                onClicked: {
                    installer.installDaemon();
                    //% "Installing daemon..."
                    loader.text = qsTrId("check_daemon.installing");
                }
            }
        }
    }
}
