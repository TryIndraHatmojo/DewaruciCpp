#ifndef DATABASECONNECTION_H
#define DATABASECONNECTION_H

#include <QObject>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QDebug>

class DatabaseConnection : public QObject
{
    Q_OBJECT

public:
    static DatabaseConnection& instance();
    
    bool initialize();
    void close();
    bool isConnected() const;
    QSqlDatabase& database() { return m_database; }
    QString lastError() const { return m_lastError; }

signals:
    void connectionEstablished();
    void connectionLost();

private:
    explicit DatabaseConnection(QObject* parent = nullptr);
    ~DatabaseConnection();
    
    static DatabaseConnection* s_instance;
    QSqlDatabase m_database;
    QString m_lastError;
    
    // Disable copy constructor and assignment operator
    DatabaseConnection(const DatabaseConnection&) = delete;
    DatabaseConnection& operator=(const DatabaseConnection&) = delete;
};

#endif // DATABASECONNECTION_H
