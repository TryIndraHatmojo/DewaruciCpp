#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QDir>
#include <QDebug>
#include "src/database/Database.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // Initialize database
    qDebug() << "Initializing database...";
    if (!Database::initialize()) {
        qCritical() << "Failed to initialize database connection";
        qDebug() << "Last error:" << Database::manager().lastError();
        // Continue anyway - app might still work without database
    } else {
        qDebug() << "Database initialized successfully";
        
        // Create tables if they don't exist
        if (!Database::createTables()) {
            qWarning() << "Failed to create database tables";
        } else {
            qDebug() << "Database tables ready";
        }
    }

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("DewaruciCpp", "Main");

    int result = app.exec();
    
    // Clean up database connection on exit
    Database::close();
    
    return result;
}
