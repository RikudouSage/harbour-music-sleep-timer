import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import "../components"

Dialog {
    id: page

    readonly property bool hoursAndMinutes: timePicker._mode === TimePickerMode.HoursAndMinutes
    readonly property int fireInSeconds: hoursAndMinutes ? timePicker.hour * 3600 + timePicker.minute * 60 : timePicker.minute * 60 + timePicker._second
    readonly property int maxWaitSeconds: waitForTrackFinishSwitch.checked ? maxWaitSecondsForIndex(maxWait.currentIndex) : 0
    readonly property bool waitForTrackFinish: waitForTrackFinishSwitch.checked

    function maxWaitSecondsForIndex(index) {
        switch (index) {
        case 0:
            return 0;
        case 1:
            return 60;
        case 2:
            return 300;
        case 3:
            return 600;
        case 4:
            return 1800;
        }

        return 0;
    }

    canAccept: fireInSeconds > 0

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height
        flickableDirection: Flickable.VerticalFlick

        Column {
            id: column

            width: parent.width
            spacing: Theme.paddingLarge

            DialogHeader {
                //% "Save"
                acceptText: qsTrId("configure_timer.accept")
            }

            Item {
                width: parent.width
                height: childrenRect.height

                TimePicker {
                    id: timePicker

                    x: isPortrait ? (column.width - width) / 2 : Theme.horizontalPageMargin
                    hourMode: DateTime.TwentyFourHours
                    _mode: TimePickerMode.MinutesAndSeconds
                    hour: 0
                    minute: 0
                    _second: 0

                    Loader {
                        anchors.centerIn: parent
                        sourceComponent: page.hoursAndMinutes ? longTimerLabelComponent : shortTimerLabelComponent
                    }
                }

                Column {
                    anchors {
                        top: isPortrait ? timePicker.bottom : parent.top
                        left: isPortrait ? parent.left : timePicker.right
                        right: parent.right
                        topMargin: isPortrait ? Theme.paddingMedium : Theme.paddingLarge
                        leftMargin: isPortrait ? 0 : Theme.paddingLarge
                    }

                    ComboBox {
                        //% "Units"
                        label: qsTrId("configure_timer.units")
                        currentIndex: timePicker._mode
                        onCurrentIndexChanged: timePicker._mode = currentIndex
                        menu: ContextMenu {
                            MenuItem {
                                //% "Hours and minutes"
                                text: qsTrId("configure_timer.hours_and_minutes")
                            }
                            MenuItem {
                                //% "Minutes and seconds"
                                text: qsTrId("configure_timer.minutes_and_seconds")
                            }
                        }
                    }

                    TextSwitch {
                        id: waitForTrackFinishSwitch

                        //% "Wait for track to finish"
                        text: qsTrId("configure_timer.wait_for_track_finish")
                        //% "Pause after the current track ends, up to the selected maximum wait."
                        description: qsTrId("configure_timer.wait_for_track_finish_description")
                    }

                    ComboBox {
                        id: maxWait

                        visible: waitForTrackFinishSwitch.checked
                        //% "Maximum wait"
                        label: qsTrId("configure_timer.maximum_wait")
                        currentIndex: 0
                        menu: ContextMenu {
                            MenuItem {
                                //: Disables the maximum wait limit, so waiting for the track to finish can continue indefinitely.
                                //% "Disabled"
                                text: qsTrId("configure_timer.max_wait_disabled")
                            }
                            MenuItem {
                                //% "1 minute"
                                text: qsTrId("configure_timer.max_wait_1_minute")
                            }
                            MenuItem {
                                //% "5 minutes"
                                text: qsTrId("configure_timer.max_wait_5_minutes")
                            }
                            MenuItem {
                                //% "10 minutes"
                                text: qsTrId("configure_timer.max_wait_10_minutes")
                            }
                            MenuItem {
                                //% "30 minutes"
                                text: qsTrId("configure_timer.max_wait_30_minutes")
                            }
                        }
                    }
                }
            }
        }

        VerticalScrollDecorator {}
    }

    Component {
        id: longTimerLabelComponent

        Column {
            spacing: -Theme.paddingMedium

            TimerValueLabel {
                value: timePicker.hour.toLocaleString()
                //: Abbreviation for hours, should be short.
                //% "h"
                unit: qsTrId("configure_timer.hours_short")
            }
            TimerValueLabel {
                value: timePicker.minute.toLocaleString()
                //% "min"
                unit: qsTrId("timer_display.minutes")
            }
        }
    }

    Component {
        id: shortTimerLabelComponent

        Column {
            spacing: -Theme.paddingMedium

            TimerValueLabel {
                value: timePicker.minute.toLocaleString()
                //% "min"
                unit: qsTrId("timer_display.minutes")
            }
            TimerValueLabel {
                value: timePicker._second.toLocaleString()
                //% "sec"
                unit: qsTrId("timer_display.seconds")
            }
        }
    }

}
