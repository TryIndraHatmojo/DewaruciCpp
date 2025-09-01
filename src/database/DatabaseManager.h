#ifndef DATABASEMANAGER_H
#define DATABASEMANAGER_H

#include <QObject>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QString>
#include <QVariant>
#include <QStringList>
#include "DatabaseConfig.h"

class DatabaseManager : public QObject
{
    Q_OBJECT
    
public:
    static DatabaseManager& instance();
    
    // Connection management
    bool initialize();
    bool isConnected() const;
    void close();
    
    // Query execution
    QSqlQuery executeQuery(const QString& queryString, const QVariantList& bindValues = QVariantList());
    bool executeNonQuery(const QString& queryString, const QVariantList& bindValues = QVariantList());
    
    // Transaction management
    bool beginTransaction();
    bool commitTransaction();
    bool rollbackTransaction();
    
    // Database utilities
    bool createTables();
    bool databaseExists() const;
    QString lastError() const;
    
    // Testing connection
    bool testConnection();

signals:
    void connected();
    void disconnected();
    void error(const QString& errorMessage);

private slots:
    void onDatabaseError(const QString& error);

private:
    DatabaseManager(QObject* parent = nullptr);
    ~DatabaseManager();
    DatabaseManager(const DatabaseManager&) = delete;
    DatabaseManager& operator=(const DatabaseManager&) = delete;
    
    bool setupDatabase();
    bool createDatabaseDirectory();
    void configureDatabaseOptions();
    void logQuery(const QString& query, const QVariantList& bindValues = QVariantList());
    
    QSqlDatabase m_database;
    DatabaseConfig* m_config;
    QString m_lastError;
    bool m_isInitialized;
};

#endif // DATABASEMANAGER_H
