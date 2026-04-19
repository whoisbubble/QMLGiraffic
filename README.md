# Giraffic

Qt/QML desktop-приложение для составления графиков работы, мероприятий, назначения персонала и ведения справочников.

## Что внутри

- Qt 6 / QML интерфейс.
- C++ `DatabaseManager`.
- PostgreSQL через `QPSQL`.
- Отдельные окна для мероприятий, сотрудников, клиентов, площадок и админ-панели.
- Подключенная иконка для Windows и macOS.
- Инструкции по деплою в `DEPLOY.md`.

## Быстрый старт

1. Открой проект в Qt Creator.
2. Убедись, что PostgreSQL запущен и база доступна.
3. При необходимости создай рядом с исполняемым файлом `giraffic.ini` на основе `config/giraffic.ini.example`.
4. Собери и запусти проект.

## Настройки базы

Пример конфигурации:

```ini
[database]
host=localhost
port=5432
name=giraffic_db

guest_user=giraffic_guest
guest_password=guest_password
```

Подробности: `DEPLOY.md`.

## Деплой

- Windows: `scripts/deploy-windows.ps1`
- macOS: `scripts/deploy-macos.sh`

Подробная инструкция находится в `DEPLOY.md`.
