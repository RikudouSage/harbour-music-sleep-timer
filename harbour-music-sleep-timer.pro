TARGET = harbour-music-sleep-timer
CONFIG += sailfishapp
QT += dbus

harbour_store {
    DEFINES += MUSIC_SLEEP_TIMER_USE_SOCKET
    DEFINES += INSTALL_BUNDLED_DAEMON

    DAEMON_RPM_DIR = $$OUT_PWD/daemon-rpms
    isEmpty(DAEMON_RPM_ARCH): DAEMON_RPM_ARCH = $$(RPM_ARCH)
    isEmpty(DAEMON_RPM_ARCH): DAEMON_RPM_ARCH = $$(MERSDK_ARCH)
    isEmpty(DAEMON_RPM_ARCH): DAEMON_RPM_ARCH = $$(MER_BUILD_ARCH)
    isEmpty(DAEMON_RPM_ARCH): DAEMON_RPM_ARCH = $$QT_ARCH
    isEmpty(DAEMON_RPM_ARCH): DAEMON_RPM_ARCH = auto

    DAEMON_RPM_DOWNLOAD_SCRIPT = $$PWD/scripts/download-harbour-daemon-rpms.sh
    DAEMON_RPM_DOWNLOAD_COMMAND = $$shell_quote($$DAEMON_RPM_DOWNLOAD_SCRIPT) --output $$shell_quote($$DAEMON_RPM_DIR) --arch $$shell_quote($$DAEMON_RPM_ARCH) --build-dir $$shell_quote($$OUT_PWD)
    !system($$DAEMON_RPM_DOWNLOAD_COMMAND): error(Failed to download bundled daemon RPMs)

    daemon_rpms.files = $$files($$DAEMON_RPM_DIR/harbour*.rpm)
    isEmpty(daemon_rpms.files): error(No bundled daemon RPMs found in $$DAEMON_RPM_DIR)
    daemon_rpms.path = /usr/share/$${TARGET}/daemon-rpms
    INSTALLS += daemon_rpms
}

DISTFILES += qml/harbour-music-sleep-timer.qml \
    qml/components/TimerDisplay.qml \
    qml/components/TimerValueLabel.qml \
    qml/cover/CoverPage.qml \
    qml/pages/ConfigureTimerPage.qml \
    qml/pages/TimerPage.qml \
    rpm/harbour-music-sleep-timer.changes.in \
    rpm/harbour-music-sleep-timer.changes.run.in \
    rpm/harbour-music-sleep-timer.spec \
    src/daemoncontroller-dbus.cpp \
    src/daemoncontroller-socket.cpp \
    scripts/download-harbour-daemon-rpms.sh \
    translations/*.ts \
    harbour-music-sleep-timer.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

CONFIG += sailfishapp_i18n sailfishapp_i18n_idbased

TRANSLATIONS += translations/harbour-music-sleep-timer-en.ts \
                translations/harbour-music-sleep-timer-cs.ts \
                translations/harbour-music-sleep-timer-nb.ts \
                translations/harbour-music-sleep-timer-sv.ts

SOURCES += src/harbour-music-sleep-timer.cpp \
    src/daemoncontroller-dbus.cpp \
    src/daemoncontroller-socket.cpp

HEADERS += \
    src/daemoncontroller.h
