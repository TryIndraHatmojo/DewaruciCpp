#include <QCoreApplication>
#include <QDebug>
#include "src/database/Database.h"
#include "src/utils/PathUtils.h"

/**
 * Program testing sederhana untuk memverifikasi konfigurasi database
 * dengan path home directory
 */
int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);
    
    qDebug() << "=== DewaruciCpp Database Path Test ===\n";
    
    // Tampilkan informasi path sistem
    qDebug() << "System Path Information:";
    qDebug().noquote() << PathUtils::getPathInfo();
    
    // Test inisialisasi database
    qDebug() << "\n=== Testing Database Initialization ===";
    if (Database::initialize()) {
        qDebug() << "✓ Database initialized successfully";
        
        qDebug() << "\nDatabase Configuration:";
        qDebug() << "- Type:" << Database::config().databaseType();
        qDebug() << "- Configured Path:" << Database::config().databasePath();
        qDebug() << "- Full Database Path:" << Database::config().fullDatabasePath();
        qDebug() << "- Database Name:" << Database::config().databaseName();
        qDebug() << "- Connection Name:" << Database::config().connectionName();
        
        // Test koneksi
        if (Database::testConnection()) {
            qDebug() << "✓ Database connection test passed";
            
            // Test pembuatan tabel
            if (Database::createTables()) {
                qDebug() << "✓ Database tables created successfully";
            } else {
                qWarning() << "✗ Failed to create database tables";
                qWarning() << "Error:" << Database::manager().lastError();
            }
        } else {
            qWarning() << "✗ Database connection test failed";
            qWarning() << "Error:" << Database::manager().lastError();
        }
        
        // Cleanup
        Database::close();
        qDebug() << "✓ Database connection closed";
        
    } else {
        qCritical() << "✗ Failed to initialize database";
        qCritical() << "Error:" << Database::manager().lastError();
        return 1;
    }
    
    qDebug() << "\n=== Test Completed Successfully ===";
    return 0;
}
