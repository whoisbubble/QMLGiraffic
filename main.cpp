#include <QCoreApplication>
#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "databasemanager.h"

int main(int argc, char *argv[])
{
    // Отключаем ошибки стилей QML системной переменной
    qputenv("QT_QUICK_CONTROLS_STYLE", "Basic");

    QGuiApplication app(argc, argv);
    QCoreApplication::setOrganizationName("Giraffic");
    QCoreApplication::setApplicationName("Giraffic");
    QGuiApplication::setWindowIcon(QIcon(":/assets/app_icon.png"));

    QQmlApplicationEngine engine;

    // 1. Создаем менеджер БД и подключаем гостя
    DatabaseManager dbManager;
    dbManager.connectToDatabase();

    // 2. Передаем в QML
    engine.rootContext()->setContextProperty("dbManager", &dbManager);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    // 3. Запускаем интерфейс
    engine.loadFromModule("QMLGiraffic", "Main");

    return app.exec();
}
