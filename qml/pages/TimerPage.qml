import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import Nemo.DBus 2.0
import Nemo.Time 1.0
import "../components"

Page {
    id: page

    readonly property double currentUnix: Math.floor(wallClock.time.getTime() / 1000)
    readonly property int totalSeconds: timerEnabled ? Math.max(0, fireAtUnix - createdAtUnix) : 0
    readonly property int remainingSeconds: timerEnabled ? Math.max(0, fireAtUnix - currentUnix) : 0
    readonly property int elapsedSeconds: timerEnabled ? Math.max(0, totalSeconds - remainingSeconds) : 0
    readonly property real progress: totalSeconds > 0 ? Math.min(1, elapsedSeconds / totalSeconds) : 0

    property bool timerEnabled: false
    property double fireAtUnix: 0
    property double createdAtUnix: 0
    property bool waitForTrackFinish: false
    property int maxWaitSeconds: 0

    function onTimerUpdated(exists, fireAtUnix, createdAtUnix, waitForTrackFinish, maxWaitSeconds) {
        page.timerEnabled = exists;
        page.fireAtUnix = exists ? fireAtUnix : 0;
        page.createdAtUnix = exists ? createdAtUnix : 0;
        page.waitForTrackFinish = waitForTrackFinish;
        page.maxWaitSeconds = maxWaitSeconds;
    }

    function onDBusError(e) {
        console.error(e);
        // todo handle UI
    }

    WallClock {
        id: wallClock

        enabled: page.timerEnabled && Qt.application.active
        updateFrequency: WallClock.Second
    }

    DBusInterface {
        id: daemon

        bus: DBus.SessionBus
        service: 'dev.rikudousage.MusicStopDaemon'
        path: '/dev/rikudousage/MusicStopDaemon'
        iface: 'dev.rikudousage.MusicStopDaemon.Controller'

        signalsEnabled: true
        watchServiceStatus: true

        // signals
        function timerFired() {
            page.onTimerUpdated(false, 0, 0, false, 0);
        }
        function timerRemoved() {
            page.onTimerUpdated(false, 0, 0, false, 0);
        }
        function timerConfigured() {
            daemon.getTimer();
        }

        // methods
        function createTimer(fireInSeconds, waitForTrackFinish, maxWaitSeconds) {
            call("CreateTimer", [
                fireInSeconds,
                waitForTrackFinish,
                maxWaitSeconds,
            ], undefined, function(e) {
                page.onDBusError(e);
            });
        }
        function cancelTimer() {
            call("CancelTimer", undefined, undefined, function(e) {
                page.onDBusError(e);
            });
        }
        function hasTimer() {
            call("HasTimer", undefined, function(hasTimer) {
                var result = hasTimer;
            }, function(e) {
                page.onDBusError(e);
            });
        }
        function getTimer() {
            typedCall("GetTimer", [], function(result) {
                var exists = result[0];
                var fireAtUnix = result[1];
                var createdAtUnix = result[2];
                var waitForTrackFinish = result[3];
                var maxWaitSeconds = result[4];

                page.onTimerUpdated(exists, fireAtUnix, createdAtUnix, waitForTrackFinish, maxWaitSeconds);
            }, function(e) {
                page.onDBusError(e);
            });
        }
    }

    Component.onCompleted: {
        daemon.getTimer();
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                visible: timerEnabled
                //% "Stop timer"
                text: qsTrId("timer.disable")
                onClicked: daemon.cancelTimer()
            }
            MenuItem {
                visible: !timerEnabled
                //% "Configure timer"
                text: qsTrId("timer.configure")
                onClicked: {
                    var dialog = pageStack.push(Qt.resolvedUrl("ConfigureTimerPage.qml"));
                    dialog.accepted.connect(function() {
                        daemon.createTimer(dialog.fireInSeconds, dialog.waitForTrackFinish, dialog.maxWaitSeconds);
                    });
                }
            }
        }

        Column {
            id: column

            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                //% "Timer"
                title: qsTrId("timer.timer")
            }

            TimerDisplay {
                width: parent.width - 2 * Theme.horizontalPageMargin
                anchors.horizontalCenter: parent.horizontalCenter
                remainingSeconds: page.remainingSeconds
                progress: page.progress
            }

            Item {
                height: Theme.paddingLarge
                width: parent.width
            }

            Label {
                x: Theme.paddingLarge
                wrapMode: Text.Wrap
                width: parent.width - x * 2
                horizontalAlignment: Text.AlignHCenter
                text: timerEnabled
                      //% "The timer is currently running. Use the pull down menu to stop it."
                      ? qsTrId("timer.status.running")
                      //% "The timer is not running. Use the pull down menu to configure it."
                      : qsTrId("timer.status.not_running")
            }
        }

        VerticalScrollDecorator {}
    }
}
