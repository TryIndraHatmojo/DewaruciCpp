#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDir>
#include <QDebug>
#include "src/database/DatabaseConnection.h"
#include "src/database/models/LinearIsotropicMaterials.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // Initialize database connection
    qDebug() << "Initializing database connection...";
    if (!DatabaseConnection::instance().initialize()) {
        qCritical() << "Failed to initialize database:" << DatabaseConnection::instance().lastError();
        // Continue anyway - app might still work without database
    } else {
        qDebug() << "Database connection initialized successfully";
    }

    // Create model instances
    LinearIsotropicMaterials* materialModel = new LinearIsotropicMaterials(&app);
    
    // Create tables
    if (DatabaseConnection::instance().isConnected()) {
        materialModel->createTable();
    }

    QQmlApplicationEngine engine;
    
    // Register model instances to QML
    engine.rootContext()->setContextProperty("materialModel", materialModel);
    
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("DewaruciCpp", "Main");

    int result = app.exec();
    
    // Clean up database connection on exit
    DatabaseConnection::instance().close();
    
    return result;
}
