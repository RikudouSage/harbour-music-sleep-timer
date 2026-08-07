#ifndef DAEMONCONTROLLER_H
#define DAEMONCONTROLLER_H

#include <QObject>

class DaemonController : public QObject
{
    Q_OBJECT
public:
    explicit DaemonController(QObject *parent = nullptr);

signals:

};

#endif // DAEMONCONTROLLER_H
