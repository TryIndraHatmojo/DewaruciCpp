#include "DatabaseConfig.h"
#include <QStandardPaths>
#include <QCoreApplication>
#include <QDebug>

DatabaseConfig& DatabaseConfig::instance()
{
    static DatabaseConfig instance;
    return instance;
}

QString DatabaseConfig::expandPath(const QString& path) const
{
    QString expandedPath = path;
    
    // Expand tilde (~) to home directory
    if (expandedPath.startsWith("~/") || expandedPath == "~") {
        QString homeDir = QStandardPaths::writableLocation(QStandardPaths::HomeLocation);
        if (expandedPath == "~") {
            expandedPath = homeDir;
        } else {
            expandedPath.replace(0, 1, homeDir);
        }
    }
    
    // Convert to native separators for current platform
    expandedPath = QDir::toNativeSeparators(expandedPath);
    
    return expandedPath;
}

bool DatabaseConfig::loadConfig(const QString& configPath)
{
    QString path = configPath;
    if (path.isEmpty()) {
        // Default ke config/database.json relatif terhadap executable
        QString appDir = QCoreApplication::applicationDirPath();
        path = QDir(appDir).absoluteFilePath("../config/database.json");
        
        // Jika tidak ada, coba di current working directory
        if (!QFile::exists(path)) {
            path = "config/database.json";
        }
    }
    
    QFile configFile(path);
    if (!configFile.open(QIODevice::ReadOnly)) {
        qWarning() << "Cannot open database config file:" << path;
        qDebug() << "Using default configuration";
        setDefaults();
        return false;
    }
    
    QByteArray data = configFile.readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    
    if (!doc.isObject()) {
        qWarning() << "Invalid JSON format in config file";
        setDefaults();
        return false;
    }
    
    QJsonObject root = doc.object();
    QJsonObject dbConfig = root["database"].toObject();
    QJsonObject loggingConfig = root["logging"].toObject();
    QJsonObject options = dbConfig["options"].toObject();
    
    // Load database config
    m_databaseType = dbConfig["type"].toString("sqlite");
    QString rawPath = dbConfig["path"].toString("~/DewaruciCpp/app/dewarucidb");
    m_databasePath = expandPath(rawPath);
    m_databaseName = dbConfig["name"].toString("dewaruci.db");
    m_connectionName = dbConfig["connectionName"].toString("DewaruciConnection");
    
    // Load database options
    m_timeout = options["timeout"].toInt(30000);
    m_synchronous = options["synchronous"].toString("NORMAL");
    m_journalMode = options["journal_mode"].toString("WAL");
    m_foreignKeys = options["foreign_keys"].toBool(true);
    
    // Load logging config
    m_loggingEnabled = loggingConfig["enabled"].toBool(true);
    m_logLevel = loggingConfig["level"].toString("INFO");
    m_logQueries = loggingConfig["logQueries"].toBool(false);
    
    qDebug() << "Database config loaded successfully from:" << path;
    return true;
}

QString DatabaseConfig::fullDatabasePath() const
{
    return QDir(m_databasePath).absoluteFilePath(m_databaseName);
}

QString DatabaseConfig::expandedDatabasePath() const
{
    return expandPath(m_databasePath);
}

void DatabaseConfig::setDefaults()
{
    m_databaseType = "sqlite";
    QString defaultPath = "~/DewaruciCpp/app/dewarucidb";
    m_databasePath = expandPath(defaultPath);
    m_databaseName = "dewaruci.db";
    m_connectionName = "DewaruciConnection";
    
    m_timeout = 30000;
    m_synchronous = "NORMAL";
    m_journalMode = "WAL";
    m_foreignKeys = true;
    
    m_loggingEnabled = true;
    m_logLevel = "INFO";
    m_logQueries = false;
}
