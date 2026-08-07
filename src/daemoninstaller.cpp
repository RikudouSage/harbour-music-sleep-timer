#include "daemoninstaller.h"

#include "sailfishapp.h"

DaemonInstaller::DaemonInstaller(QObject *parent)
    : QObject(parent), rpmsPath(SailfishApp::pathTo("daemon-rpms").toLocalFile())
{
}
