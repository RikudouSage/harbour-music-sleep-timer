import QtQuick 2.0
import Sailfish.Silica 1.0

import "pages"
import "cover"

ApplicationWindow {
    Component {
        id: timer
        TimerPage {}
    }
    Component {
        id: daemonCheck
        CheckDaemonPage {}
    }
    Component {
        id: coverMain
        CoverPage {}
    }
    Component {
        id: coverEmpty
        CoverEmpty {}
    }

    id: app
    initialPage: installBundled ? daemonCheck : timer
    cover: installBundled ? coverEmpty : coverMain
    allowedOrientations: defaultAllowedOrientations
}
