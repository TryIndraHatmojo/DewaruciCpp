#include "DatabaseShipConnection.h"
#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>
#include <QSqlDriver>
#include <QStandardPaths>
#include <QDir>
#include <QCoreApplication>
#include <QFileInfo>
#include <QDebug>

DatabaseShipConnection* DatabaseShipConnection::s_instance = nullptr;

DatabaseShipConnection& DatabaseShipConnection::instance()
{
    if (!s_instance) {
        s_instance = new DatabaseShipConnection();
    }
    return *s_instance;
}

DatabaseShipConnection::DatabaseShipConnection(QObject* parent)
    : QObject(parent)
{
}

DatabaseShipConnection::~DatabaseShipConnection()
{
    close();
}

bool DatabaseShipConnection::initialize()
{
    // Setup SQLite database
    m_database = QSqlDatabase::addDatabase("QSQLITE", "ShipConnection");
    
    // Set database path to project folder data/shipsdb.db
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
    
    QString dbPath = QDir(projectRoot).absoluteFilePath("data/shipsdb.db");
    
    // Create database directory if it doesn't exist
    QDir dbDir = QFileInfo(dbPath).absoluteDir();
    if (!dbDir.exists()) {
        dbDir.mkpath(".");
    }
    
    m_database.setDatabaseName(dbPath);
    
    if (!m_database.open()) {
        m_lastError = QString("Failed to open ship database: %1").arg(m_database.lastError().text());
        qCritical() << "DatabaseShipConnection::initialize() -" << m_lastError;
        qCritical() << "  Attempted path:" << dbPath;
        qCritical() << "  Project root:" << projectRoot;
        qCritical() << "  App dir:" << appDirPath;
        return false;
    }
    
    qDebug() << "DatabaseShipConnection::initialize() - Ship database opened:" << dbPath;
    emit connectionEstablished();
    
    qDebug() << "DatabaseShipConnection::initialize() - Successfully initialized ship database";
    return true;
}

void DatabaseShipConnection::close()
{
    if (m_database.isOpen()) {
        m_database.close();
        emit connectionLost();
        qDebug() << "DatabaseShipConnection::close() - Ship database connection closed";
    }
}

bool DatabaseShipConnection::isConnected() const
{
    return m_database.isOpen() && m_database.isValid();
}

QSqlDatabase DatabaseShipConnection::getDatabase() const
{
    return m_database;
}

QString DatabaseShipConnection::getLastError() const
{
    return m_lastError;
}