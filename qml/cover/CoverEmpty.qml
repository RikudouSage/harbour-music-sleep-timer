import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {
    id: cover

    Column {
        anchors.centerIn: parent
        width: parent.width - 2 * Theme.paddingLarge
        spacing: Theme.paddingMedium

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
}
