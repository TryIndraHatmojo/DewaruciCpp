#include "DatabaseManager.h"
#include <QSqlDriver>
#include <QDir>
#include <QStandardPaths>
#include <QDebug>
#include <QCoreApplication>

DatabaseManager& DatabaseManager::instance()
{
    static DatabaseManager instance;
    return instance;
}

DatabaseManager::DatabaseManager(QObject* parent)
    : QObject(parent)
    , m_config(&DatabaseConfig::instance())
    , m_isInitialized(false)
{
}

DatabaseManager::~DatabaseManager()
{
    close();
}

bool DatabaseManager::initialize()
{
    if (m_isInitialized) {
        return true;
    }
    
    // Load configuration
    m_config->loadConfig();
    
    // Setup database connection
    if (!setupDatabase()) {
        return false;
    }
    
    m_isInitialized = true;
    emit connected();
    
    qDebug() << "Database initialized successfully";
    return true;
}

bool DatabaseManager::setupDatabase()
{
    // Remove existing connection if it exists
    if (QSqlDatabase::contains(m_config->connectionName())) {
        QSqlDatabase::removeDatabase(m_config->connectionName());
    }
    
    // Create database connection
    m_database = QSqlDatabase::addDatabase("QSQLITE", m_config->connectionName());
    
    // Create directory if it doesn't exist
    if (!createDatabaseDirectory()) {
        m_lastError = "Failed to create database directory";
        return false;
    }
    
    // Set database path
    QString dbPath = m_config->fullDatabasePath();
    m_database.setDatabaseName(dbPath);
    
    // Open connection
    if (!m_database.open()) {
        m_lastError = QString("Failed to open database: %1").arg(m_database.lastError().text());
        qCritical() << m_lastError;
        return false;
    }
    
    // Configure database options
    configureDatabaseOptions();
    
    // Test the connection
    if (!testConnection()) {
        m_lastError = "Database connection test failed";
        return false;
    }
    
    qDebug() << "Database connection established:" << dbPath;
    return true;
}

bool DatabaseManager::createDatabaseDirectory()
{
    QDir dir;
    QString path = m_config->databasePath();
    
    if (!dir.exists(path)) {
        if (!dir.mkpath(path)) {
            qCritical() << "Failed to create database directory:" << path;
            return false;
        }
        qDebug() << "Created database directory:" << path;
    }
    
    return true;
}

void DatabaseManager::configureDatabaseOptions()
{
    if (!m_database.isOpen()) {
        return;
    }
    
    QSqlQuery query(m_database);
    
    // Set timeout
    query.exec(QString("PRAGMA busy_timeout = %1").arg(m_config->timeout()));
    
    // Set synchronous mode
    query.exec(QString("PRAGMA synchronous = %1").arg(m_config->synchronous()));
    
    // Set journal mode
    query.exec(QString("PRAGMA journal_mode = %1").arg(m_config->journalMode()));
    
    // Enable/disable foreign keys
    query.exec(QString("PRAGMA foreign_keys = %1").arg(m_config->foreignKeys() ? "ON" : "OFF"));
    
    if (m_config->loggingEnabled()) {
        qDebug() << "Database PRAGMA settings applied";
    }
}

bool DatabaseManager::isConnected() const
{
    return m_database.isOpen() && m_database.isValid();
}

void DatabaseManager::close()
{
    if (m_database.isOpen()) {
        m_database.close();
        emit disconnected();
        qDebug() << "Database connection closed";
    }
    
    if (QSqlDatabase::contains(m_config->connectionName())) {
        QSqlDatabase::removeDatabase(m_config->connectionName());
    }
    
    m_isInitialized = false;
}

QSqlQuery DatabaseManager::executeQuery(const QString& queryString, const QVariantList& bindValues)
{
    QSqlQuery query(m_database);
    
    if (!m_database.isOpen()) {
        m_lastError = "Database is not connected";
        return query;
    }
    
    if (!query.prepare(queryString)) {
        m_lastError = QString("Query preparation failed: %1").arg(query.lastError().text());
        qWarning() << m_lastError;
        return query;
    }
    
    // Bind values
    for (int i = 0; i < bindValues.size(); ++i) {
        query.bindValue(i, bindValues.at(i));
    }
    
    if (!query.exec()) {
        m_lastError = QString("Query execution failed: %1").arg(query.lastError().text());
        qWarning() << m_lastError;
        emit error(m_lastError);
    } else {
        logQuery(queryString, bindValues);
    }
    
    return query;
}

bool DatabaseManager::executeNonQuery(const QString& queryString, const QVariantList& bindValues)
{
    QSqlQuery query = executeQuery(queryString, bindValues);
    return query.lastError().type() == QSqlError::NoError;
}

bool DatabaseManager::beginTransaction()
{
    if (!m_database.isOpen()) {
        m_lastError = "Database is not connected";
        return false;
    }
    
    bool success = m_database.transaction();
    if (!success) {
        m_lastError = QString("Failed to begin transaction: %1").arg(m_database.lastError().text());
        qWarning() << m_lastError;
    }
    
    return success;
}

bool DatabaseManager::commitTransaction()
{
    if (!m_database.isOpen()) {
        m_lastError = "Database is not connected";
        return false;
    }
    
    bool success = m_database.commit();
    if (!success) {
        m_lastError = QString("Failed to commit transaction: %1").arg(m_database.lastError().text());
        qWarning() << m_lastError;
    }
    
    return success;
}

bool DatabaseManager::rollbackTransaction()
{
    if (!m_database.isOpen()) {
        m_lastError = "Database is not connected";
        return false;
    }
    
    bool success = m_database.rollback();
    if (!success) {
        m_lastError = QString("Failed to rollback transaction: %1").arg(m_database.lastError().text());
        qWarning() << m_lastError;
    }
    
    return success;
}

bool DatabaseManager::testConnection()
{
    if (!m_database.isOpen()) {
        return false;
    }
    
    QSqlQuery query("SELECT 1", m_database);
    bool success = query.exec() && query.next();
    
    if (!success) {
        m_lastError = QString("Connection test failed: %1").arg(query.lastError().text());
        qWarning() << m_lastError;
    }
    
    return success;
}

bool DatabaseManager::databaseExists() const
{
    return QFile::exists(m_config->fullDatabasePath());
}

QString DatabaseManager::lastError() const
{
    return m_lastError;
}

bool DatabaseManager::createTables()
{
    if (!isConnected()) {
        m_lastError = "Database is not connected";
        return false;
    }
    
    // Example table creation - customize according to your needs
    QStringList createQueries = {
        R"(
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL UNIQUE,
            email TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
        )",
        
        R"(
        CREATE TABLE IF NOT EXISTS settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
        )",
        
        R"(
        CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
        )",
        
        R"(
        CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
        )"
    };
    
    bool success = true;
    
    // Begin transaction
    if (!beginTransaction()) {
        return false;
    }
    
    for (const QString& queryString : createQueries) {
        if (!executeNonQuery(queryString)) {
            success = false;
            break;
        }
    }
    
    if (success) {
        commitTransaction();
        qDebug() << "Database tables created successfully";
    } else {
        rollbackTransaction();
        qWarning() << "Failed to create database tables";
    }
    
    return success;
}

void DatabaseManager::logQuery(const QString& query, const QVariantList& bindValues)
{
    if (!m_config->loggingEnabled() || !m_config->logQueries()) {
        return;
    }
    
    QString logMessage = QString("SQL Query: %1").arg(query);
    if (!bindValues.isEmpty()) {
        QStringList values;
        for (const QVariant& value : bindValues) {
            values << value.toString();
        }
        logMessage += QString(" | Bind Values: [%1]").arg(values.join(", "));
    }
    
    qDebug() << logMessage;
}

void DatabaseManager::onDatabaseError(const QString& error)
{
    m_lastError = error;
    qCritical() << "Database Error:" << error;
    emit this->error(error);
}
