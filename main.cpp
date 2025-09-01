#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDir>
#include <QDebug>
#include "src/database/MaterialDatabase.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // Initialize database
    qDebug() << "Initializing material database...";
    if (!MaterialDatabase::instance().initialize()) {
        qCritical() << "Failed to initialize database:" << MaterialDatabase::instance().lastError();
        // Continue anyway - app might still work without database
    } else {
        qDebug() << "Material database initialized successfully";
    }

    QQmlApplicationEngine engine;
    
    // Register MaterialDatabase instance to QML
    engine.rootContext()->setContextProperty("materialDatabase", &MaterialDatabase::instance());
    
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("DewaruciCpp", "Main");

    int result = app.exec();
    
    // Clean up database connection on exit
    MaterialDatabase::instance().close();
    
    return result;
}
