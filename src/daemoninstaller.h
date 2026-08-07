#ifndef DAEMONINSTALLER_H
#define DAEMONINSTALLER_H

#include <QObject>

class DaemonInstaller : public QObject
{
    Q_OBJECT
public:
    explicit DaemonInstaller(QObject *parent = nullptr);

signals:

private:
    const QString rpmsPath;
};

#endif // DAEMONINSTALLER_H
