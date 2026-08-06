import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.DBus 2.0
import Nemo.Time 1.0
import "../components"

CoverBackground {
    id: cover

    readonly property double currentUnix: Math.floor(wallClock.time.getTime() / 1000)
    readonly property int totalSeconds: timerEnabled ? Math.max(0, fireAtUnix - createdAtUnix) : 0
    readonly property int remainingSeconds: timerEnabled ? Math.max(0, fireAtUnix - currentUnix) : 0
    readonly property int elapsedSeconds: timerEnabled ? Math.max(0, totalSeconds - remainingSeconds) : 0
    readonly property real progress: totalSeconds > 0 ? Math.min(1, elapsedSeconds / totalSeconds) : 0

    property bool timerEnabled: false
    property double fireAtUnix: 0
    property double createdAtUnix: 0

    function onTimerUpdated(exists, fireAtUnix, createdAtUnix) {
        cover.timerEnabled = exists;
        cover.fireAtUnix = exists ? fireAtUnix : 0;
        cover.createdAtUnix = exists ? createdAtUnix : 0;
    }

    function onDBusError(e) {
        console.error(e);
    }

    WallClock {
        id: wallClock

        enabled: cover.timerEnabled
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

        function timerFired() {
            cover.onTimerUpdated(false, 0, 0);
        }
        function timerRemoved() {
            cover.onTimerUpdated(false, 0, 0);
        }
        function timerConfigured() {
            daemon.getTimer();
        }

        function getTimer() {
            typedCall("GetTimer", [], function(result) {
                var exists = result[0];
                var fireAtUnix = result[1];
                var createdAtUnix = result[2];

                cover.onTimerUpdated(exists, fireAtUnix, createdAtUnix);
            }, function(e) {
                cover.onDBusError(e);
            });
        }

        function cancelTimer() {
            call("CancelTimer", undefined, undefined, function(e) {
                cover.onDBusError(e);
            });
        }
    }

    Component.onCompleted: {
        daemon.getTimer();
    }

    Column {
        anchors.centerIn: parent
        width: parent.width - 2 * Theme.paddingLarge
        spacing: Theme.paddingMedium

        TimerDisplay {
            width: parent.width
            maximumDiameter: Math.min(width, cover.height - parent.spacing - Theme.fontSizeSmall - 2 * Theme.paddingLarge)
            scaleRatio: 0.7
            remainingSeconds: cover.remainingSeconds
            progress: cover.progress
        }

        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            truncationMode: TruncationMode.Fade
            maximumLineCount: 1
            color: Theme.primaryColor
            font.pixelSize: Theme.fontSizeSmall
            //% "Music Sleep Timer"
            text: qsTrId("cover.title")
        }
    }

    CoverActionList {
        enabled: cover.timerEnabled

        CoverAction {
            iconSource: "image://theme/icon-cover-cancel"
            onTriggered: daemon.cancelTimer()
        }
    }
}
