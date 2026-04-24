#include "databasemanager.h"
#include <QClipboard>
#include <QCoreApplication>
#include <QCryptographicHash>
#include <QDir>
#include <QFileInfo>
#include <QGuiApplication>
#include <QSettings>
#include <QStringList>
#include <QStandardPaths>

namespace {
struct DatabaseConfig
{
    QString host;
    int port;
    QString name;
    QString guestUser;
    QString guestPassword;
    QString adminUser;
    QString adminPassword;
    QString managerUser;
    QString managerPassword;
};

QString readTextSetting(QSettings &settings, const char *envName, const char *settingsKey, const QString &fallback)
{
    const QString envValue = qEnvironmentVariable(envName);
    if (!envValue.isEmpty()) {
        return envValue;
    }

    return settings.value(settingsKey, fallback).toString();
}

int readIntSetting(QSettings &settings, const char *envName, const char *settingsKey, int fallback)
{
    bool ok = false;
    const QString envValue = qEnvironmentVariable(envName);
    if (!envValue.isEmpty()) {
        const int value = envValue.toInt(&ok);
        if (ok) {
            return value;
        }
    }

    const int value = settings.value(settingsKey, fallback).toInt(&ok);
    return ok ? value : fallback;
}

DatabaseConfig loadDatabaseConfig()
{
    QString configPath = qEnvironmentVariable("GIRAFFIC_CONFIG_PATH");
    if (configPath.isEmpty()) {
        const QString appConfigDir = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);
        const QString appConfigPath = appConfigDir + "/giraffic.ini";
        const QString bundlePath = QCoreApplication::applicationDirPath() + "/giraffic.ini";
        const QString cwdPath = QDir::currentPath() + "/giraffic.ini";

        if (QFileInfo::exists(appConfigPath)) {
            configPath = appConfigPath;
        } else if (QFileInfo::exists(bundlePath)) {
            configPath = bundlePath;
        } else if (QFileInfo::exists(cwdPath)) {
            configPath = cwdPath;
        } else {
            configPath = bundlePath;
        }
    }

    QSettings settings(configPath, QSettings::IniFormat);

    return {
        readTextSetting(settings, "GIRAFFIC_DB_HOST", "database/host", "localhost"),
        readIntSetting(settings, "GIRAFFIC_DB_PORT", "database/port", 5432),
        readTextSetting(settings, "GIRAFFIC_DB_NAME", "database/name", "giraffic_db"),
        readTextSetting(settings, "GIRAFFIC_DB_GUEST_USER", "database/guest_user", "giraffic_guest"),
        readTextSetting(settings, "GIRAFFIC_DB_GUEST_PASSWORD", "database/guest_password", "guest_password"),
        readTextSetting(settings, "GIRAFFIC_DB_ADMIN_USER", "database/admin_user", "giraffic_admin"),
        readTextSetting(settings, "GIRAFFIC_DB_ADMIN_PASSWORD", "database/admin_password", "admin"),
        readTextSetting(settings, "GIRAFFIC_DB_MANAGER_USER", "database/manager_user", "giraffic_manager"),
        readTextSetting(settings, "GIRAFFIC_DB_MANAGER_PASSWORD", "database/manager_password", "manager"),
    };
}
}

DatabaseManager::DatabaseManager(QObject *parent)
    : QObject(parent),
      m_isConnected(false),
      m_currentUserRole("giraffic_guest")
{
}

DatabaseManager::~DatabaseManager() {
    disconnectDatabase();
}

bool DatabaseManager::isConnected() const { return m_isConnected; }
QString DatabaseManager::lastError() const { return m_lastError; }

void DatabaseManager::setLastError(const QString &err) {
    QString cleanErr = err;

    // Необходимо убрать все что идет после context, там мусор
    if (cleanErr.contains("CONTEXT:")) {
        cleanErr = cleanErr.split("CONTEXT:").first();
    }

    // Приставки девольные убираем
    cleanErr.remove("ОШИБКА:  ");
    cleanErr.remove("ERROR:  ");
    cleanErr.remove("(P0001)");

    m_lastError = cleanErr.trimmed(); // Чистый текст ошибки

    emit errorOccurred(m_lastError); // Сообщаем

    // Логируем
    qDebug() << "DB_ERROR (FULL):" << err;
}

void DatabaseManager::disconnectDatabase() {
    if (QSqlDatabase::contains(QSqlDatabase::defaultConnection)) {
        if (db.isValid() && db.isOpen()) {
            db.close();
        }
        db = QSqlDatabase();

        QSqlDatabase::removeDatabase(QSqlDatabase::defaultConnection);
    }

    m_isConnected = false;
    emit connectionChanged(m_isConnected);
}

bool DatabaseManager::connectToDatabase(const QString &user, const QString &password) {
    // удаляем старое подключение
    disconnectDatabase();

    const DatabaseConfig config = loadDatabaseConfig();
    const QString dbUser = user.isEmpty() ? config.guestUser : user;
    const QString dbPassword = password.isEmpty() ? config.guestPassword : password;

    if (!QSqlDatabase::drivers().contains("QPSQL")) {
        setLastError("PostgreSQL Qt driver QPSQL is not loaded. Check that the QPSQL plugin is deployed with the app and that libpq is bundled correctly.");
        emit connectionChanged(m_isConnected);
        return false;
    }

    db = QSqlDatabase::addDatabase("QPSQL");
    db.setHostName(config.host);
    db.setPort(config.port);
    db.setDatabaseName(config.name);
    db.setUserName(dbUser);
    db.setPassword(dbPassword);

    m_isConnected = db.open();

    if (!m_isConnected) {
        setLastError(db.lastError().text());
        qDebug() << "ОШИБКА КОННЕКТА:" << db.lastError().text();
    } else {
        setLastError("Подключено успешно");
        qDebug() << "БД Успешно подключена под пользователем:" << dbUser;
    }

    emit connectionChanged(m_isConnected);
    return m_isConnected;
}

// ==========================================================
// РЕАЛИЗАЦИЯ ПРОЦЕДУР И ФУНКЦИЙ
// ==========================================================

bool DatabaseManager::registerUser(const QString &username, const QString &passwordHash) {
    // 1. Превращаем обычный пароль в SHA-256 хэш
    QString hashedPassword = QString(QCryptographicHash::hash(passwordHash.toUtf8(), QCryptographicHash::Sha256).toHex());

    QSqlQuery query;
    query.prepare("CALL giraffic.register_app_user(:u, :p)");
    query.bindValue(":u", username);
    query.bindValue(":p", hashedPassword); // Отправляем в базу ХЭШ через бинды (ANTI SQL INJECTIONs)!

    if (!query.exec()) {
        setLastError(query.lastError().text());
        return false;
    }
    return true;
}

QString DatabaseManager::currentUserRole() const {
    return m_currentUserRole;
}

bool DatabaseManager::loginUser(const QString &username, const QString &passwordHash) {
    // Хэшируем пароль
    QString hashedPassword = QString(QCryptographicHash::hash(passwordHash.toUtf8(), QCryptographicHash::Sha256).toHex());

    QString roleCode = "";
    QString errorMsg = "";

    {
        QSqlQuery query;
        query.prepare("CALL giraffic.sp_process_login_new(:username, :password, :ip, :user_agent, :role_code, :err)");

        query.bindValue(":username", username);
        query.bindValue(":password", hashedPassword);
        query.bindValue(":ip", "127.0.0.1");
        query.bindValue(":user_agent", "Giraffic Qt Desktop App");

        query.bindValue(":role_code", "", QSql::Out);
        query.bindValue(":err", "", QSql::Out);

        if (!query.exec()) {
            setLastError(query.lastError().databaseText());
            return false;
        }

        if (query.next()) {
            roleCode = query.value(0).toString();
            errorMsg = query.value(1).toString();
        } else {
            roleCode = query.boundValue(":role_code").toString();
            errorMsg = query.boundValue(":err").toString();
        }
    }

    // В скобках, чтобы query уничтожился

    // Если база вернула ошибку логина/пароля
    if (!errorMsg.isEmpty()) {
        setLastError(errorMsg);
        return false;
    }

    if (roleCode.isEmpty()) roleCode = "giraffic_guest";
    m_currentUserRole = roleCode;

    qDebug() << "Аутентификация успешна. Роль:" << m_currentUserRole;


    // Заканчиваем старое соединение
    disconnectDatabase();

    const DatabaseConfig config = loadDatabaseConfig();

    // ПЕРЕКЛЮЧЕНИЕ РОЛИ БД
    bool ok = false;
    if (m_currentUserRole == "giraffic_admin") {
        qDebug() << "Переподключаемся к БД как giraffic_admin...";
        ok = connectToDatabase(config.adminUser, config.adminPassword);
    }
    else if (m_currentUserRole == "giraffic_manager") {
        qDebug() << "Переподключаемся к БД как giraffic_manager...";
        ok = connectToDatabase(config.managerUser, config.managerPassword);
    }
    else {
        // ОБЯЗАТЕЛЬНО возвращаем гостя, если роль не админ и не менеджер
        qDebug() << "Возвращаем права гостя...";
        ok = connectToDatabase();
    }

    // 3. Только если база реально открылась, уведомляем интерфейс
    if (ok) {
        emit currentUserRoleChanged(m_currentUserRole);
        return true;
    } else {
        setLastError("Критическая ошибка переподключения: " + lastError());
        return false;
    }
}

void DatabaseManager::logoutUser() {
    qDebug() << "Инициирован выход. Отключаем текущую роль...";
    disconnectDatabase();

    // Сбрасываем роль обратно на GUEST
    m_currentUserRole = "giraffic_guest";
    emit currentUserRoleChanged(m_currentUserRole);

    // Подключаемся дефолтным гостем, чтобы окно логина могло проверять пароли
    connectToDatabase();
    qDebug() << "Возврат к giraffic_guest выполнен.";
}

double DatabaseManager::getCompanyEfficiency(int month, int year) {
    QSqlQuery query;
    query.prepare("SELECT giraffic.get_company_efficiency(:m, :y)");
    query.bindValue(":m", month);
    query.bindValue(":y", year);

    if (query.exec() && query.next()) {
        return query.value(0).toDouble();
    }
    setLastError(query.lastError().text());
    return 0.0;
}

QVariantList DatabaseManager::getScheduleEvents() {
    QVariantList list;
    QSqlQuery query("SELECT * FROM giraffic.vw_schedule_events ORDER BY starts_at ASC");

    while (query.next()) {
        QVariantMap map;
        map["title"] = query.value("title").toString();
        map["client"] = query.value("client_name").toString();
        map["venue"] = query.value("venue_name").toString();
        map["team"] = query.value("team").toString();
        list.append(map);
    }
    return list;
}

int DatabaseManager::getVenuePopularity(qint64 venueId) {
    QSqlQuery query;
    query.prepare("SELECT giraffic.get_venue_popularity(:id)");
    query.bindValue(":id", venueId);

    if (query.exec() && query.next()) {
        return query.value(0).toInt(); // Возвращаем результат
    }

    setLastError(query.lastError().text());
    return 0;
}

// ==========================================================
// РЕАЛИЗАЦИЯ ОСТАЛЬНЫХ ПРОЦЕДУР ДОБАВЛЕНИЯ
// ==========================================================

bool DatabaseManager::addWorker(const QString &fullName, const QString &phone, const QString &email, bool isActive) {
    QSqlQuery query;
    query.prepare("CALL giraffic.add_worker(:name, :phone, :email, :active)");
    query.bindValue(":name", fullName);
    query.bindValue(":phone", phone);
    query.bindValue(":email", email);
    query.bindValue(":active", isActive);
    if (!query.exec()) { setLastError(query.lastError().databaseText()); return false; }
    return true;
}

bool DatabaseManager::addVenue(const QString &name, const QString &address) {
    QSqlQuery query;
    query.prepare("CALL giraffic.add_venue(:name, :address)");
    query.bindValue(":name", name);
    query.bindValue(":address", address);
    if (!query.exec()) { setLastError(query.lastError().databaseText()); return false; }
    return true;
}

bool DatabaseManager::addRole(const QString &name) {
    QSqlQuery query;
    query.prepare("CALL giraffic.add_role(:name)");
    query.bindValue(":name", name);
    if (!query.exec()) { setLastError(query.lastError().databaseText()); return false; }
    return true;
}

bool DatabaseManager::addClient(const QString &name, const QString &phone, const QString &email, int discountPercent) {
    QSqlQuery query;
    query.prepare("CALL giraffic.add_client(:name, :phone, :email, :discount)");
    query.bindValue(":name", name);
    query.bindValue(":phone", phone);
    query.bindValue(":email", email);
    query.bindValue(":discount", discountPercent);
    if (!query.exec()) { setLastError(query.lastError().databaseText()); return false; }
    return true;
}

bool DatabaseManager::addEvent(const QString &title, qint64 clientId, qint64 venueId, const QDateTime &startsAt, const QDateTime &endsAt, const QString &notes) {
    QSqlQuery query;
    query.prepare("CALL giraffic.add_event(:title, :client, :venue, :start, :end, :notes)");
    query.bindValue(":title", title);
    query.bindValue(":client", clientId);
    query.bindValue(":venue", venueId);
    query.bindValue(":start", startsAt);
    query.bindValue(":end", endsAt);
    query.bindValue(":notes", notes);
    if (!query.exec()) { setLastError(query.lastError().databaseText()); return false; }
    return true;
}

bool DatabaseManager::assign3Workers(qint64 eventId, qint64 w1, qint64 r1, double p1, qint64 w2, qint64 r2, double p2, qint64 w3, qint64 r3, double p3) {
    QSqlQuery query;
    query.prepare("CALL giraffic.assign_3_workers(:ev, :w1,:r1,:p1, :w2,:r2,:p2, :w3,:r3,:p3)");
    query.bindValue(":ev", eventId);
    query.bindValue(":w1", w1); query.bindValue(":r1", r1); query.bindValue(":p1", p1);
    query.bindValue(":w2", w2); query.bindValue(":r2", r2); query.bindValue(":p2", p2);
    query.bindValue(":w3", w3); query.bindValue(":r3", r3); query.bindValue(":p3", p3);
    if (!query.exec()) { setLastError(query.lastError().databaseText()); return false; }
    return true;
}

bool DatabaseManager::addAppRole(const QString &code, const QString &name) {
    QSqlQuery query;
    query.prepare("CALL giraffic.add_app_role(:code, :name)");
    query.bindValue(":code", code); query.bindValue(":name", name);
    if (!query.exec()) { setLastError(query.lastError().databaseText()); return false; }
    return true;
}

bool DatabaseManager::assignAppUserRole(qint64 appUserId, qint64 appRoleId) {
    QSqlQuery query;
    query.prepare("CALL giraffic.assign_app_user_role(:uid, :rid)");
    query.bindValue(":uid", appUserId); query.bindValue(":rid", appRoleId);
    if (!query.exec()) { setLastError(query.lastError().databaseText()); return false; }
    return true;
}

// ==========================================================
// РЕАЛИЗАЦИЯ ФУНКЦИЙ И ПРЕДСТАВЛЕНИЙ
// ==========================================================

double DatabaseManager::getWorkerBonus(qint64 workerId, int month, int year) {
    QSqlQuery query;
    query.prepare("SELECT giraffic.get_worker_bonus(:w, :m, :y)");
    query.bindValue(":w", workerId); query.bindValue(":m", month); query.bindValue(":y", year);
    if (query.exec() && query.next()) return query.value(0).toDouble();
    setLastError(query.lastError().databaseText());
    return 0.0;
}

QVariantList DatabaseManager::getWorkerStats(qint64 workerId) {
    QVariantList list;
    QSqlQuery query;
    query.prepare("SELECT * FROM giraffic.get_worker_stats(:w)");
    query.bindValue(":w", workerId);
    if (query.exec()) {
        while (query.next()) {
            QVariantMap map;
            map["month_num"] = query.value("month_num").toInt();
            map["work_count"] = query.value("work_count").toInt();
            list.append(map);
        }
    } else { setLastError(query.lastError().databaseText()); }
    return list;
}

QVariantList DatabaseManager::getScheduleRows() {
    QVariantList list;
    QSqlQuery query("SELECT * FROM giraffic.vw_schedule_rows ORDER BY starts_at ASC");
    while (query.next()) {
        QVariantMap map;
        map["day"] = query.value("day").toString();
        map["title"] = query.value("title").toString();
        map["worker"] = query.value("full_name").toString();
        map["role"] = query.value("role_name").toString();
        map["pay"] = query.value("pay_amount").toDouble();
        list.append(map);
    }
    return list;
}

QVariantList DatabaseManager::getWorkerBusyIntervals() {
    QVariantList list;
    QSqlQuery query("SELECT * FROM giraffic.vw_worker_busy_intervals ORDER BY starts_at ASC");
    while (query.next()) {
        QVariantMap map;
        map["worker"] = query.value("full_name").toString();
        map["start"] = query.value("starts_at").toDateTime().toString("dd.MM.yyyy HH:mm");
        map["end"] = query.value("ends_at").toDateTime().toString("dd.MM.yyyy HH:mm");
        map["type"] = query.value("busy_type").toString();
        map["desc"] = query.value("description").toString();
        list.append(map);
    }
    return list;
}

// ==========================================================
// СПИСКИ ДЛЯ QML COMBOBOX
// ==========================================================

QVariantList DatabaseManager::getWorkersList() {
    QVariantList list;
    QSqlQuery query;
    // Берем только активных сотрудников и сортируем по алфавиту
    if (query.exec("SELECT worker_id, full_name FROM giraffic.workers WHERE is_active = true ORDER BY full_name ASC")) {
        while (query.next()) {
            QVariantMap map;
            map["value"] = query.value("worker_id").toLongLong(); // ID пойдет под капот
            map["text"] = query.value("full_name").toString();    // Имя покажем пользователю
            list.append(map);
        }
    } else {
        setLastError(query.lastError().databaseText());
    }
    return list;
}

QVariantList DatabaseManager::getRolesList() {
    QVariantList list;
    QSqlQuery query;
    // Берем все роли персонала
    if (query.exec("SELECT role_id, name FROM giraffic.roles ORDER BY name ASC")) {
        while (query.next()) {
            QVariantMap map;
            map["value"] = query.value("role_id").toLongLong();
            map["text"] = query.value("name").toString();
            list.append(map);
        }
    } else {
        setLastError(query.lastError().databaseText());
    }
    return list;
}
// ==========================================================
// МЕТОДЫ ДЛЯ ГЛАВНОГО ОКНА (ManageWindow)
// ==========================================================

QVariantList DatabaseManager::getEventsList(const QString &fromDate, const QString &toDate) {
    QVariantList list;

    // Базовый запрос
    QString sql =
        "SELECT e.event_id, e.title, to_char(e.starts_at, 'DD.MM.YYYY HH24:MI') as date_str, "
        "COUNT(a.worker_id) as assigned_count "
        "FROM giraffic.events e "
        "LEFT JOIN giraffic.assignments a ON a.event_id = e.event_id "
        "WHERE 1=1";

    // Если ввели дату "ОТ"
    if (!fromDate.isEmpty()) {
        sql += " AND e.starts_at >= to_timestamp(:from, 'DD.MM.YYYY')";
    }
    // Если ввели дату "ДО" (добавляем интервал, чтобы включить весь день до 23:59:59)
    if (!toDate.isEmpty()) {
        sql += " AND e.starts_at <= to_timestamp(:to, 'DD.MM.YYYY') + interval '1 day - 1 second'";
    }

    sql += " GROUP BY e.event_id, e.title, e.starts_at ORDER BY e.starts_at ASC";

    QSqlQuery query;
    query.prepare(sql);

    if (!fromDate.isEmpty()) query.bindValue(":from", fromDate);
    if (!toDate.isEmpty()) query.bindValue(":to", toDate);

    if (query.exec()) {
        while (query.next()) {
            QVariantMap map;
            map["id"] = query.value("event_id").toLongLong();
            map["title"] = query.value("title").toString();
            map["date"] = query.value("date_str").toString();
            map["assignedCount"] = query.value("assigned_count").toInt();
            list.append(map);
        }
    } else {
        setLastError(query.lastError().databaseText());
    }

    return list;
}

bool DatabaseManager::assignWorker(qint64 eventId, qint64 workerId, qint64 roleId, double payAmount) {
    QSqlQuery query;
    // Делаем прямую вставку. Если такой работник уже на этой роли в этом событии - БД выдаст ошибку благодаря UNIQUE индексу
    query.prepare("INSERT INTO giraffic.assignments (event_id, worker_id, role_id, pay_amount) VALUES (:e, :w, :r, :p)");
    query.bindValue(":e", eventId);
    query.bindValue(":w", workerId);
    query.bindValue(":r", roleId);
    query.bindValue(":p", payAmount);

    if (!query.exec()) {
        setLastError(query.lastError().databaseText());
        return false;
    }
    return true;
}

QVariantList DatabaseManager::getClientsList() {
    QVariantList list;
    QSqlQuery query;
    if (query.exec("SELECT client_id, name FROM giraffic.clients ORDER BY name ASC")) {
        while (query.next()) {
            QVariantMap map;
            map["value"] = query.value("client_id").toLongLong();
            map["text"] = query.value("name").toString();
            list.append(map);
        }
    }
    return list;
}

QVariantList DatabaseManager::getVenuesList() {
    QVariantList list;
    QSqlQuery query;
    if (query.exec("SELECT venue_id, name FROM giraffic.venues ORDER BY name ASC")) {
        while (query.next()) {
            QVariantMap map;
            map["value"] = query.value("venue_id").toLongLong();
            map["text"] = query.value("name").toString();
            list.append(map);
        }
    }
    return list;
}

bool DatabaseManager::addWorkerUnavailability(qint64 workerId, const QDateTime &start, const QDateTime &end, const QString &reason) {
    QSqlQuery query;
    query.prepare("INSERT INTO giraffic.worker_unavailability (worker_id, starts_at, ends_at, reason) VALUES (:w, :s, :e, :r)");
    query.bindValue(":w", workerId);
    query.bindValue(":s", start);
    query.bindValue(":e", end);
    query.bindValue(":r", reason);
    if (!query.exec()) {
        setLastError(query.lastError().databaseText());
        return false;
    }
    return true;
}

QString DatabaseManager::getEventDetailsString(qint64 eventId) {
    QString result = "📝 ИНФОРМАЦИЯ О МЕРОПРИЯТИИ\n--------------------------------\n";

    // 1. Достаем заметки/комментарии
    QSqlQuery q1;
    q1.prepare("SELECT notes FROM giraffic.events WHERE event_id = :id");
    q1.bindValue(":id", eventId);
    if (q1.exec() && q1.next()) {
        QString notes = q1.value(0).toString();
        result += "Комментарий: " + (notes.isEmpty() ? "Нет данных" : notes) + "\n\n";
    }

    // 2. Достаем список работников и их зарплаты
    result += "👥 НАЗНАЧЕННАЯ КОМАНДА\n--------------------------------\n";
    QSqlQuery q2;
    q2.prepare("SELECT w.full_name, r.name, a.pay_amount "
               "FROM giraffic.assignments a "
               "JOIN giraffic.workers w ON a.worker_id = w.worker_id "
               "JOIN giraffic.roles r ON a.role_id = r.role_id "
               "WHERE a.event_id = :id");
    q2.bindValue(":id", eventId);

    bool hasWorkers = false;
    double totalPay = 0;

    if (q2.exec()) {
        while (q2.next()) {
            hasWorkers = true;
            QString wName = q2.value(0).toString();
            QString rName = q2.value(1).toString();
            double pay = q2.value(2).toDouble();
            totalPay += pay;

            result += QString("• %1 (%2) — %3 руб.\n").arg(wName, rName, QString::number(pay));
        }
    }

    if (!hasWorkers) {
        result += "Пока никто не назначен.\n";
    } else {
        result += QString("--------------------------------\nОбщий фонд ЗП: %1 руб.").arg(totalPay);
    }

    return result;
}
// ==========================================================
// БУФЕР ОБМЕНА И ОТЧЕТЫ
// ==========================================================

void DatabaseManager::copyToClipboard(const QString &text) {
    if (QClipboard *clipboard = QGuiApplication::clipboard()) {
        clipboard->setText(text);
    }
}

QString DatabaseManager::getAllEventsText(const QString &fromDate, const QString &toDate) {
    QString fullText = "ОТЧЕТ ПО МЕРОПРИЯТИЯМ\n================================\n\n";
    QVariantList events = getEventsList(fromDate, toDate); // Используем твой же фильтр

    if (events.isEmpty()) {
        return fullText + "Нет мероприятий в выбранном периоде.";
    }

    for (const QVariant &v : events) {
        QVariantMap map = v.toMap();
        fullText += "МЕРОПРИЯТИЕ: " + map["title"].toString() + " (Дата: " + map["date"].toString() + ")\n";
        fullText += getEventDetailsString(map["id"].toLongLong()) + "\n\n";
    }
    return fullText;
}

// ==========================================================
// АДМИН ПАНЕЛЬ
// ==========================================================

QVariantList DatabaseManager::getAppUsersList() {
    QVariantList list;
    QSqlQuery query;
    if (query.exec("SELECT app_user_id, username FROM giraffic.app_users ORDER BY username ASC")) {
        while (query.next()) {
            QVariantMap map;
            map["value"] = query.value("app_user_id").toLongLong();
            map["text"] = query.value("username").toString();
            list.append(map);
        }
    }
    return list;
}

QVariantList DatabaseManager::getAppRolesList() {
    QVariantList list;
    QSqlQuery query;
    if (query.exec("SELECT app_role_id, name FROM giraffic.app_roles ORDER BY name ASC")) {
        while (query.next()) {
            QVariantMap map;
            map["value"] = query.value("app_role_id").toLongLong();
            map["text"] = query.value("name").toString();
            list.append(map);
        }
    }
    return list;
}

QVariantList DatabaseManager::getTableRecords(const QString &tableName) {
    QVariantList list;
    QSqlQuery query;
    QString sql;

    // Подбираем запрос в зависимости от таблицы
    if (tableName == "events") sql = "SELECT event_id as id, title as name FROM giraffic.events ORDER BY event_id DESC";
    else if (tableName == "workers") sql = "SELECT worker_id as id, full_name as name FROM giraffic.workers ORDER BY worker_id DESC";
    else if (tableName == "clients") sql = "SELECT client_id as id, name FROM giraffic.clients ORDER BY client_id DESC";
    else if (tableName == "venues") sql = "SELECT venue_id as id, name FROM giraffic.venues ORDER BY venue_id DESC";
    else if (tableName == "app_users") sql = "SELECT app_user_id as id, username as name FROM giraffic.app_users ORDER BY app_user_id DESC";
    else return list;

    if (query.exec(sql)) {
        while (query.next()) {
            QVariantMap map;
            map["value"] = query.value("id").toLongLong();
            map["text"] = query.value("name").toString() + " (ID: " + query.value("id").toString() + ")";
            list.append(map);
        }
    } else {
        setLastError(query.lastError().databaseText());
    }
    return list;
}

bool DatabaseManager::deleteRecord(const QString &tableName, qint64 id) {
    QSqlQuery query;
    QString pkColumn;

    // Определяем имя колонки Primary Key
    if (tableName == "events") pkColumn = "event_id";
    else if (tableName == "workers") pkColumn = "worker_id";
    else if (tableName == "clients") pkColumn = "client_id";
    else if (tableName == "venues") pkColumn = "venue_id";
    else if (tableName == "app_users") pkColumn = "app_user_id";
    else {
        setLastError("Неизвестная таблица");
        return false;
    }

    query.prepare("DELETE FROM giraffic." + tableName + " WHERE " + pkColumn + " = :id");
    query.bindValue(":id", id);

    if (!query.exec()) {
        setLastError(query.lastError().databaseText());
        return false;
    }
    return true;
}

QVariantList DatabaseManager::getAuditLogs(const QString &logType, int page) {
    QVariantList list;
    QSqlQuery query;
    int pageSize = 10;
    int offset = (page - 1) * pageSize;
    QString sql;

    qDebug() << "Запрос аудита:" << logType << "Страница:" << page;

    if (logType == "login_audit") {
        // Делаем LEFT JOIN, чтобы вытянуть username по app_user_id
        sql = QString("SELECT l.occurred_at, l.success, COALESCE(u.username, 'ID:' || l.app_user_id::text) "
                      "FROM giraffic.login_audit l "
                      "LEFT JOIN giraffic.app_users u ON l.app_user_id = u.app_user_id "
                      "ORDER BY l.occurred_at DESC LIMIT %1 OFFSET %2").arg(pageSize).arg(offset);
    }
    else if (logType == "audit_ddl") {
        sql = QString("SELECT occurred_at, db_user, command_tag FROM giraffic.audit_ddl "
                      "ORDER BY occurred_at DESC LIMIT %1 OFFSET %2").arg(pageSize).arg(offset);
    }
    else if (logType == "audit_dml") {
        sql = QString("SELECT occurred_at, db_user, action FROM giraffic.audit_dml "
                      "ORDER BY occurred_at DESC LIMIT %1 OFFSET %2").arg(pageSize).arg(offset);
    }

    if (!query.exec(sql)) {
        QVariantMap errMap;
        errMap["logText"] = "Ошибка БД: " + query.lastError().databaseText();
        list.append(errMap);
        return list;
    }

    while (query.next()) {
        QVariantMap map;
        QString time = query.value(0).toDateTime().toString("HH:mm:ss (dd.MM)");

        if (logType == "login_audit") {
            bool ok = query.value(1).toBool();
            QString user = query.value(2).toString();
            if (user.isEmpty()) user = "Неизвестен";

            // Теперь показываем и юзера, и статус!
            map["logText"] = QString("%1 | Юзер: %2 | Вход: %3").arg(time, user, ok ? "УСПЕХ" : "ОТКАЗ");
        } else {
            QString user = query.value(1).toString();
            QString action = query.value(2).toString();
            map["logText"] = QString("%1 | Юзер: %2 | %3").arg(time, user, action);
        }
        list.append(map);
    }

    return list;
}

bool DatabaseManager::clearTable(const QString &tableName) {
    // Разрешаем полностью очищать только журналы аудита!
    QStringList allowedTables = {"login_audit", "audit_ddl", "audit_dml"};
    if (!allowedTables.contains(tableName)) {
        setLastError("ОШИБКА БЕЗОПАСНОСТИ: Недопустимое имя таблицы для полной очистки!");
        return false;
    }

    QSqlQuery query;
    // TRUNCATE мгновенно и бесследно очищает таблицу
    if (!query.exec("TRUNCATE TABLE giraffic." + tableName + " CASCADE")) {
        setLastError(query.lastError().databaseText());
        return false;
    }
    return true;
}
