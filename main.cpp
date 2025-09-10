#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDir>
#include <QDebug>
#include "src/database/DatabaseConnection.h"
#include "src/database/DatabaseShipConnection.h"
#include "src/database/models/LinearIsotropicMaterials.h"
#include "src/database/models/FrameArrangementXZ.h"
#include "src/database/models/FrameArrangementYZ.h"
#include "src/controllers/StructureProfileTableController.h"
#include "src/controllers/FrameArrangementXZController.h"
#include "src/controllers/FrameArrangementYZController.h"

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

    // Initialize ship database connection
    qDebug() << "Initializing ship database connection...";
    if (!DatabaseShipConnection::instance().initialize()) {
        qCritical() << "Failed to initialize ship database:" << DatabaseShipConnection::instance().getLastError();
        // Continue anyway - app might still work without ship database
    } else {
        qDebug() << "Ship database connection initialized successfully";
    }

    // Create model instances
    LinearIsotropicMaterials* materialModel = new LinearIsotropicMaterials(&app);
    FrameArrangementXZ* frameXZModel = new FrameArrangementXZ(&app);
    FrameArrangementYZ* frameYZModel = new FrameArrangementYZ(&app);
    
    // Create controller instances
    StructureProfileTableController* profileController = new StructureProfileTableController(&app);
    FrameArrangementXZController* frameXZController = new FrameArrangementXZController(&app);
    FrameArrangementYZController* frameYZController = new FrameArrangementYZController(&app);
    
    // Set model for controllers
    frameXZController->setModel(frameXZModel);
    frameYZController->setModel(frameYZModel);
    
    // Create tables
    if (DatabaseConnection::instance().isConnected()) {
        materialModel->createTable();
        profileController->initialize();
    }

    // Create ship database tables
    if (DatabaseShipConnection::instance().isConnected()) {
        frameXZModel->createTable();
        frameXZModel->loadData();
        frameYZModel->createTable();
        frameYZModel->loadData();
        
        // Initialize controller data
        frameXZController->getFrameXZList();
    frameYZController->getFrameYZAll();
    }

    QQmlApplicationEngine engine;
    
    // Register model instances to QML
    engine.rootContext()->setContextProperty("materialModel", materialModel);
    engine.rootContext()->setContextProperty("frameXZModel", frameXZModel);
    engine.rootContext()->setContextProperty("frameYZModel", frameYZModel);
    engine.rootContext()->setContextProperty("profileController", profileController);
    engine.rootContext()->setContextProperty("frameXZController", frameXZController);
    engine.rootContext()->setContextProperty("frameYZController", frameYZController);
    
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
    DatabaseShipConnection::instance().close();
    
    return result;
}
