import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: root

    property int remainingSeconds: 0
    property real progress: 0
    readonly property int remainingMinutes: Math.floor(remainingSeconds / 60)
    readonly property int remainingSecondsPart: remainingSeconds % 60
    readonly property real normalizedProgress: Math.max(0, Math.min(1, progress))

    height: timerCircle.height

    Item {
        id: timerCircle

        width: Math.min(root.width, Theme.itemSizeHuge * 2)
        height: width
        anchors.horizontalCenter: parent.horizontalCenter

        Canvas {
            id: progressCanvas

            anchors.fill: parent
            antialiasing: true

            onPaint: {
                var context = getContext("2d");
                var lineWidth = Math.max(4, Math.round(Theme.paddingMedium));
                var radius = width / 2 - lineWidth;
                var center = width / 2;
                var start = -Math.PI / 2;
                var end = start + root.normalizedProgress * Math.PI * 2;

                context.clearRect(0, 0, width, height);
                context.lineCap = "round";
                context.lineWidth = lineWidth;
                context.strokeStyle = Theme.rgba(Theme.primaryColor, Theme.opacityFaint);
                context.beginPath();
                context.arc(center, center, radius, 0, Math.PI * 2);
                context.stroke();

                if (root.normalizedProgress > 0) {
                    context.strokeStyle = Theme.highlightColor;
                    context.beginPath();
                    context.arc(center, center, radius, start, end);
                    context.stroke();
                }
            }

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            Connections {
                target: root

                onNormalizedProgressChanged: progressCanvas.requestPaint()
            }

            Component.onCompleted: requestPaint()
        }

        Column {
            anchors.centerIn: parent
            spacing: Theme.paddingSmall

            Row {
                spacing: Theme.paddingSmall
                visible: root.remainingMinutes !== 0
                anchors.horizontalCenter: parent.horizontalCenter

                Label {
                    id: minutes

                    text: root.remainingMinutes.toLocaleString()
                    color: Theme.primaryColor
                    font.pixelSize: Theme.fontSizeHuge
                    verticalAlignment: Text.AlignBottom
                }

                Label {
                    //: An abbreaviation for minutes, should be short
                    //% "min"
                    text: qsTrId("timer_display.minutes")
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeMedium
                    anchors.baseline: minutes.baseline
                    verticalAlignment: Text.AlignBottom
                }
            }

            Row {
                spacing: Theme.paddingSmall
                visible: root.remainingSecondsPart !== 0 || root.remainingMinutes === 0
                anchors.horizontalCenter: parent.horizontalCenter

                Label {
                    id: seconds

                    text: root.remainingSecondsPart.toLocaleString()
                    color: Theme.primaryColor
                    font.pixelSize: Theme.fontSizeHuge
                    verticalAlignment: Text.AlignBottom
                }

                Label {
                    //: An abbreviation for seconds, should be short
                    //% "sec"
                    text: qsTrId("timer_display.seconds")
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeMedium
                    anchors.baseline: seconds.baseline
                    verticalAlignment: Text.AlignBottom
                }
            }
        }
    }
}
