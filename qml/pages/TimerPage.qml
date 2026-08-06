import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import Nemo.DBus 2.0

Page {
    id: page

    function onTimerUpdated(exists, fireAtUnix, waitForTrackFinish, maxWaitSeconds) {
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
            page.onTimerUpdated(false, 0, false, 0);
        }
        function timerRemoved() {
            page.onTimerUpdated(false, 0, false, 0);
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
                console.error(e)
            });
        }
        function cancelTimer() {
            call("CancelTimer", undefined, undefined, function(e) {
                console.error(e);
            });
        }
        function hasTimer() {
            call("HasTimer", undefined, function(hasTimer) {
                var result = hasTimer;
            }, function(e) {
                console.error(e);
            });
        }
        function getTimer() {
            typedCall("GetTimer", [], function(result) {
                var exists = result[0];
                var fireAtUnix = result[1];
                var waitForTrackFinish = result[2];
                var maxWaitSeconds = result[3];

                page.onTimerUpdated(exists, fireAtUnix, waitForTrackFinish, maxWaitSeconds);
            }, function(e) {
                console.error(e);
            });
        }
    }

    Component.onCompleted: {
        daemon.getTimer();
    }
}
