import QtQuick 2.0
import Sailfish.Silica 1.0

Row {
    property string value
    property string unit

    spacing: Theme.paddingSmall

    Label {
        id: valueLabel

        text: parent.value
        color: Theme.primaryColor
        font.pixelSize: Theme.fontSizeHuge
        verticalAlignment: Text.AlignBottom
    }

    Label {
        text: parent.unit
        color: Theme.secondaryColor
        font.pixelSize: Theme.fontSizeMedium
        anchors.baseline: valueLabel.baseline
        verticalAlignment: Text.AlignBottom
    }
}
