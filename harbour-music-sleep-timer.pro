TARGET = harbour-music-sleep-timer
CONFIG += sailfishapp
SOURCES += src/harbour-music-sleep-timer.cpp
QT += dbus

DISTFILES += qml/harbour-music-sleep-timer.qml \
    qml/cover/CoverPage.qml \
    qml/pages/TimerPage.qml \
    rpm/harbour-music-sleep-timer.changes.in \
    rpm/harbour-music-sleep-timer.changes.run.in \
    rpm/harbour-music-sleep-timer.spec \
    translations/*.ts \
    harbour-music-sleep-timer.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

CONFIG += sailfishapp_i18n sailfishapp_i18n_idbased

TRANSLATIONS += translations/harbour-music-sleep-timer-en.ts \
                translations/harbour-music-sleep-timer-cs.ts
