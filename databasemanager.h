#ifndef DATABASEMANAGER_H
#define DATABASEMANAGER_H

#include <QObject>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QSqlRecord>
#include <QVariant>
#include <QDebug>
#include <QDateTime>

class DatabaseManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isConnected READ isConnected NOTIFY connectionChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY errorOccurred)
    Q_PROPERTY(QString currentUserRole READ currentUserRole NOTIFY currentUserRoleChanged)

public:
    explicit DatabaseManager(QObject *parent = nullptr);
    ~DatabaseManager();

    bool isConnected() const;
    QString lastError() const;
    QString currentUserRole() const;

    // --- БАЗОВЫЕ ПОДКЛЮЧЕНИЯ И АВТОРИЗАЦИЯ ---
    Q_INVOKABLE bool connectToDatabase(const QString &user = QString(), const QString &password = QString()); // по умолчанию гостевой
    Q_INVOKABLE void disconnectDatabase();
    Q_INVOKABLE bool loginUser(const QString &username, const QString &passwordHash);
    Q_INVOKABLE bool registerUser(const QString &username, const QString &passwordHash);
    Q_INVOKABLE void logoutUser();

    // --- ПРОЦЕДУРЫ ДОБАВЛЕНИЯ (СПРАВОЧНИКИ) ---
    Q_INVOKABLE bool addWorker(const QString &fullName, const QString &phone, const QString &email, bool isActive = true);
    Q_INVOKABLE bool addVenue(const QString &name, const QString &address);
    Q_INVOKABLE bool addRole(const QString &name);
    Q_INVOKABLE bool addClient(const QString &name, const QString &phone, const QString &email, int discountPercent = 0);
    Q_INVOKABLE bool addEvent(const QString &title, qint64 clientId, qint64 venueId, const QDateTime &startsAt, const QDateTime &endsAt, const QString &notes = "");

    // --- ПРОЦЕДУРЫ НАЗНАЧЕНИЯ РАБОТНИКОВ ---
    Q_INVOKABLE bool assign3Workers(qint64 eventId,
                                    qint64 w1, qint64 r1, double p1,
                                    qint64 w2, qint64 r2, double p2,
                                    qint64 w3, qint64 r3, double p3);

    // --- СИСТЕМНЫЕ ПРОЦЕДУРЫ (РОЛИ) ---
    Q_INVOKABLE bool addAppRole(const QString &code, const QString &name);
    Q_INVOKABLE bool assignAppUserRole(qint64 appUserId, qint64 appRoleId);

    // --- ФУНКЦИИ (ВОЗВРАТ ЗНАЧЕНИЙ) ---
    Q_INVOKABLE double getCompanyEfficiency(int month, int year);
    Q_INVOKABLE int getVenuePopularity(int venueId);
    Q_INVOKABLE double getWorkerBonus(qint64 workerId, int month, int year);
    Q_INVOKABLE QVariantList getWorkerStats(qint64 workerId);
    Q_INVOKABLE bool assignWorker(qint64 eventId, qint64 workerId, qint64 roleId, double payAmount);

    // --- ПРЕДСТАВЛЕНИЯ (VIEWS) ---
    Q_INVOKABLE QVariantList getScheduleEvents();
    Q_INVOKABLE QVariantList getScheduleRows();
    Q_INVOKABLE QVariantList getWorkerBusyIntervals();

    // --- ДЛЯ ВЫПАДАЮЩИХ СПИСКОВ ---
    Q_INVOKABLE QVariantList getWorkersList();
    Q_INVOKABLE QVariantList getRolesList();
    Q_INVOKABLE QVariantList getEventsList(const QString &fromDate = "", const QString &toDate = "");
    Q_INVOKABLE QVariantList getClientsList();
    Q_INVOKABLE QVariantList getVenuesList();

    // ДОП. ДОБАВИЛ
    Q_INVOKABLE bool addWorkerUnavailability(qint64 workerId, const QDateTime &start, const QDateTime &end, const QString &reason);
    Q_INVOKABLE QString getEventDetailsString(qint64 eventId);

    // Для буфера обмена и текста
    Q_INVOKABLE void copyToClipboard(const QString &text);
    Q_INVOKABLE QString getAllEventsText(const QString &fromDate = "", const QString &toDate = "");

    // Для Админ Панели
    Q_INVOKABLE QVariantList getAppUsersList();
    Q_INVOKABLE QVariantList getAppRolesList();
    Q_INVOKABLE QVariantList getTableRecords(const QString &tableName);
    Q_INVOKABLE bool deleteRecord(const QString &tableName, qint64 id);
    Q_INVOKABLE QVariantList getAuditLogs(const QString &logType, int page = 1);
    Q_INVOKABLE bool clearTable(const QString &tableName);

signals:
    void connectionChanged(bool connected);
    void errorOccurred(QString errorMsg);
    void currentUserRoleChanged(QString role);

private:
    QSqlDatabase db;
    bool m_isConnected;
    QString m_lastError;
    QString m_currentUserRole;

    void setLastError(const QString &err);
};

#endif // DATABASEMANAGER_H
