#ifndef DATABASESHIPCONNECTION_H
#define DATABASESHIPCONNECTION_H

#include <QObject>
#include <QSqlDatabase>
#include <QSqlError>

class DatabaseShipConnection : public QObject
{
    Q_OBJECT

public:
    static DatabaseShipConnection& instance();
    
    bool initialize();
    void close();
    bool isConnected() const;
    QSqlDatabase getDatabase() const;
    QString getLastError() const;

signals:
    void connectionEstablished();
    void connectionLost();

private:
    explicit DatabaseShipConnection(QObject* parent = nullptr);
    ~DatabaseShipConnection();
    
    // Prevent copying
    DatabaseShipConnection(const DatabaseShipConnection&) = delete;
    DatabaseShipConnection& operator=(const DatabaseShipConnection&) = delete;
    
    static DatabaseShipConnection* s_instance;
    QSqlDatabase m_database;
    QString m_lastError;
};

#endif // DATABASESHIPCONNECTION_H
