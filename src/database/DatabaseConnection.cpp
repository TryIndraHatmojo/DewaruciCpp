#include "DatabaseConnection.h"
#include <QStandardPaths>
#include <QDir>
#include <QCoreApplication>
#include <QFileInfo>

DatabaseConnection* DatabaseConnection::s_instance = nullptr;

DatabaseConnection& DatabaseConnection::instance()
{
    if (!s_instance) {
        s_instance = new DatabaseConnection();
    }
    return *s_instance;
}

DatabaseConnection::DatabaseConnection(QObject* parent)
    : QObject(parent)
{
}

DatabaseConnection::~DatabaseConnection()
{
    close();
}

bool DatabaseConnection::initialize()
{
    // Setup SQLite database
    m_database = QSqlDatabase::addDatabase("QSQLITE", "MainConnection");
    
    // Set database path to project folder data/dewaruci.db
    QString appDirPath = QCoreApplication::applicationDirPath();
    QString projectRoot;
    
    // Navigate to project root from build directory
    QDir appDir(appDirPath);
    if (appDir.dirName().contains("build") || appDir.dirName().contains("Debug") || appDir.dirName().contains("Release")) {
        // We're in build directory, go up to project root
        appDir.cdUp(); // from Debug
        if (appDir.dirName().contains("Desktop_Qt")) {
            appDir.cdUp(); // from Desktop_Qt_6_9_1_MinGW_64_bit-Debug
        }
        if (appDir.dirName() == "build") {
            appDir.cdUp(); // from build
        }
        projectRoot = appDir.absolutePath();
    } else {
        // Assume we're already in project root
        projectRoot = appDirPath;
    }
    
    QString dbPath = QDir(projectRoot).absoluteFilePath("data/dewaruci.db");
    
    // Create database directory if it doesn't exist
    QDir dbDir = QFileInfo(dbPath).absoluteDir();
    if (!dbDir.exists()) {
        dbDir.mkpath(".");
    }
    
    m_database.setDatabaseName(dbPath);
    
    if (!m_database.open()) {
        m_lastError = QString("Failed to open database: %1").arg(m_database.lastError().text());
        qCritical() << "DatabaseConnection::initialize() -" << m_lastError;
        qCritical() << "  Attempted path:" << dbPath;
        qCritical() << "  Project root:" << projectRoot;
        qCritical() << "  App dir:" << appDirPath;
        return false;
    }
    
    qDebug() << "DatabaseConnection::initialize() - Database opened:" << dbPath;
    emit connectionEstablished();
    
    qDebug() << "DatabaseConnection::initialize() - Successfully initialized";
    return true;
}

void DatabaseConnection::close()
{
    if (m_database.isOpen()) {
        m_database.close();
        emit connectionLost();
        qDebug() << "DatabaseConnection::close() - Database connection closed";
    }
}

bool DatabaseConnection::isConnected() const
{
    return m_database.isOpen() && m_database.isValid();
}
