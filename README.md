# Giraffic

Giraffic — это desktop-приложение на Qt/QML для составления графиков работы, управления мероприятиями, сотрудниками, площадками, клиентами и админ-задачами.

Проект использует:

- Qt 6 + QML для интерфейса
- C++ `DatabaseManager`
- PostgreSQL через `QPSQL`
- ролевую модель доступа: гость, менеджер, админ

## Что умеет приложение

- показывать ленту мероприятий
- создавать мероприятия
- назначать сотрудников на мероприятия
- работать со справочниками сотрудников, клиентов и площадок
- открывать админ-панель
- считать статистику в админке

## Роли

- `giraffic_guest` — может только смотреть мероприятия и открывать их детали
- `giraffic_manager` — работает с мероприятиями, назначениями, сотрудниками, клиентами и площадками
- `giraffic_admin` — полный доступ, включая роли, удаление данных, журналы и статистику

## Структура проекта

- `Main.qml` — окно входа
- `ManageWindow.qml` — основное рабочее окно
- `AdminWindow.qml` — админ-панель
- `databasemanager.cpp/.h` — подключение к БД и SQL-логика
- `config/giraffic.ini.example` — пример конфига базы
- `scripts/` — локальные скрипты деплоя
- `.github/workflows/desktop-builds.yml` — GitHub Actions для Windows, macOS и Linux

## Быстрый старт для разработки

1. Установи Qt Creator и Qt Desktop.
2. Установи PostgreSQL.
3. Создай базу и роли, которые использует проект.
4. Скопируй `config/giraffic.ini.example`.
5. Переименуй копию в `giraffic.ini`.
6. Положи этот файл рядом с исполняемым файлом во время локального запуска или используй переменные окружения.
7. Открой проект в Qt Creator и собери его.

## Настройки базы

Пример:

```ini
[database]
host=localhost
port=5432
name=giraffic_db

guest_user=giraffic_guest
guest_password=guest_password

admin_user=giraffic_admin
admin_password=admin

manager_user=giraffic_manager
manager_password=manager
```

Поддерживаются переменные окружения:

```text
GIRAFFIC_DB_HOST
GIRAFFIC_DB_PORT
GIRAFFIC_DB_NAME
GIRAFFIC_DB_GUEST_USER
GIRAFFIC_DB_GUEST_PASSWORD
GIRAFFIC_DB_ADMIN_USER
GIRAFFIC_DB_ADMIN_PASSWORD
GIRAFFIC_DB_MANAGER_USER
GIRAFFIC_DB_MANAGER_PASSWORD
GIRAFFIC_CONFIG_PATH
```

`GIRAFFIC_CONFIG_PATH` может указывать прямо на нужный `giraffic.ini`.

## Где приложение ищет `giraffic.ini`

Порядок такой:

1. путь из `GIRAFFIC_CONFIG_PATH`
2. системная папка конфигов приложения
3. `giraffic.ini` рядом с исполняемым файлом
4. текущая рабочая папка

На практике:

- Windows: обычно кладём `giraffic.ini` рядом с `Giraffic.exe`
- macOS: лучший путь — `~/Library/Application Support/Giraffic/giraffic.ini`
- Linux: лучший путь — `~/.config/Giraffic/giraffic.ini`

Для быстрого теста на macOS можно положить файл прямо сюда:

```text
Giraffic.app/Contents/MacOS/giraffic.ini
```

## Сборка и деплой

Локальные скрипты:

- Windows: `scripts/deploy-windows.ps1`
- macOS: `scripts/deploy-macos.sh`
- Linux: `scripts/deploy-linux.sh`

Автоматическая сборка через GitHub Actions:

- Windows artifact
- macOS artifact
- Linux artifact

Workflow:

```text
.github/workflows/desktop-builds.yml
```

Подробности — в `DEPLOY.md`.

## Как использовать GitHub Actions

1. Запушь проект на GitHub.
2. Открой репозиторий.
3. Перейди во вкладку `Actions`.
4. Выбери `Desktop Builds`.
5. Нажми `Run workflow`.
6. Дождись окончания сборки.
7. Скачай артефакты:
   - `giraffic-windows`
   - `giraffic-macos`
   - `giraffic-linux`

## Имя приложения и метаданные

Имя приложения и свойства файла настраиваются в `CMakeLists.txt`.

Главные переменные:

- `APP_PRODUCT_NAME`
- `APP_DISPLAY_NAME`
- `APP_EXECUTABLE_NAME`
- `APP_COMPANY_NAME`
- `APP_FILE_DESCRIPTION`
- `APP_COPYRIGHT`
- `APP_BUNDLE_ID`

Шаблон метаданных для Windows:

```text
cmake/windows_version.rc.in
```

Шаблон метаданных для macOS:

```text
cmake/Info.plist.in
```

## Важный момент про PostgreSQL

Приложение использует `QPSQL`, поэтому для деплоя нужны не только Qt-библиотеки, но и:

- Qt SQL plugin для PostgreSQL
- клиентская библиотека `libpq`
- дополнительные зависимости под конкретную ОС

Если приложение пишет `Driver not loaded`, это обычно проблема с PostgreSQL client libraries, а не с `giraffic.ini`.

## Что не надо коммитить

Не коммить:

- реальный `giraffic.ini`
- пароли
- `build/`
- `dist/`
- локальные файлы Qt Creator

`config/giraffic.ini.example` в репозитории хранить можно.
