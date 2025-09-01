#ifndef DATABASECONFIG_H
#define DATABASECONFIG_H

#include <QString>
#include <QJsonObject>
#include <QJsonDocument>
#include <QFile>
#include <QDir>

class DatabaseConfig
{
public:
    static DatabaseConfig& instance();
    
    bool loadConfig(const QString& configPath = "");
    
    // Getters untuk konfigurasi database
    QString databaseType() const { return m_databaseType; }
    QString databasePath() const { return m_databasePath; }
    QString databaseName() const { return m_databaseName; }
    QString connectionName() const { return m_connectionName; }
    QString fullDatabasePath() const;
    QString expandedDatabasePath() const;
    
    // Database options
    int timeout() const { return m_timeout; }
    QString synchronous() const { return m_synchronous; }
    QString journalMode() const { return m_journalMode; }
    bool foreignKeys() const { return m_foreignKeys; }
    
    // Logging options
    bool loggingEnabled() const { return m_loggingEnabled; }
    QString logLevel() const { return m_logLevel; }
    bool logQueries() const { return m_logQueries; }

private:
    DatabaseConfig() { setDefaults(); }
    ~DatabaseConfig() = default;
    DatabaseConfig(const DatabaseConfig&) = delete;
    DatabaseConfig& operator=(const DatabaseConfig&) = delete;
    
    void setDefaults();
    QString expandPath(const QString& path) const;
    
    QString m_databaseType = "sqlite";
    QString m_databasePath;
    QString m_databaseName = "dewaruci.db";
    QString m_connectionName = "DewaruciConnection";
    
    int m_timeout = 30000;
    QString m_synchronous = "NORMAL";
    QString m_journalMode = "WAL";
    bool m_foreignKeys = true;
    
    bool m_loggingEnabled = true;
    QString m_logLevel = "INFO";
    bool m_logQueries = false;
};

#endif // DATABASECONFIG_H
