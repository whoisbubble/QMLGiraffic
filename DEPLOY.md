# Giraffic: деплой и настройки

Это Qt/QML приложение с PostgreSQL. Само приложение деплоится через Qt Deploy Tools, а база должна быть либо локально установлена у пользователя, либо доступна на сервере.

## 1. Где редактировать переменные окружения

В приложении поддерживаются такие переменные:

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
```

Но для деплоя удобнее не переменные окружения, а файл `giraffic.ini`, который лежит рядом с `.exe` или внутри `.app`. Переменные окружения хороши для разработки, а `giraffic.ini` проще отдать другому человеку вместе с приложением.

### Windows: временно, только для текущей консоли

```powershell
$env:GIRAFFIC_DB_HOST = "localhost"
$env:GIRAFFIC_DB_PORT = "5432"
$env:GIRAFFIC_DB_NAME = "giraffic_db"
$env:GIRAFFIC_DB_GUEST_USER = "giraffic_guest"
$env:GIRAFFIC_DB_GUEST_PASSWORD = "guest_password"
```

После закрытия PowerShell эти значения исчезнут.

### Windows: постоянно для текущего пользователя

```powershell
[Environment]::SetEnvironmentVariable("GIRAFFIC_DB_HOST", "localhost", "User")
[Environment]::SetEnvironmentVariable("GIRAFFIC_DB_PORT", "5432", "User")
[Environment]::SetEnvironmentVariable("GIRAFFIC_DB_NAME", "giraffic_db", "User")
[Environment]::SetEnvironmentVariable("GIRAFFIC_DB_GUEST_USER", "giraffic_guest", "User")
[Environment]::SetEnvironmentVariable("GIRAFFIC_DB_GUEST_PASSWORD", "guest_password", "User")
```

После этого надо закрыть и заново открыть Qt Creator/PowerShell/приложение.

### Windows: через интерфейс

1. Открой `Пуск`.
2. Найди `Изменение системных переменных среды`.
3. Нажми `Переменные среды`.
4. В блоке `Переменные пользователя` нажми `Создать`.
5. Введи имя, например `GIRAFFIC_DB_HOST`.
6. Введи значение, например `localhost`.
7. Повтори для остальных переменных.
8. Перезапусти приложение.

### macOS/Linux: временно из терминала

```bash
export GIRAFFIC_DB_HOST="localhost"
export GIRAFFIC_DB_PORT="5432"
export GIRAFFIC_DB_NAME="giraffic_db"
export GIRAFFIC_DB_GUEST_USER="giraffic_guest"
export GIRAFFIC_DB_GUEST_PASSWORD="guest_password"
```

Если запускать `.app` двойным кликом на macOS, переменные из терминала обычно не применяются. Для macOS-деплоя лучше использовать `giraffic.ini`.

## 2. Рекомендуемый способ: giraffic.ini

Файл-пример уже есть:

```text
config/giraffic.ini.example
```

Скопируй его рядом с приложением и переименуй в:

```text
giraffic.ini
```

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

Важно: `giraffic.ini` с реальными паролями не надо коммитить на GitHub. В репозиторий кладём только `giraffic.ini.example`.

## 3. Что делать с базой у других людей

Сейчас приложение использует PostgreSQL и SQL-объекты проекта:

- схему `giraffic`;
- таблицы;
- views;
- хранимые процедуры;
- роли БД `giraffic_guest`, `giraffic_admin`, `giraffic_manager`.

Поэтому у пользователя есть два нормальных варианта.

### Вариант A: у каждого своя локальная база

Подходит для курсовой и демонстрации.

На каждом компьютере:

1. Установить PostgreSQL.
2. Создать базу `giraffic_db`.
3. Накатить SQL-дамп твоей схемы.
4. Создать роли и пароли, которые указаны в `giraffic.ini`.
5. Запустить приложение.

В `giraffic.ini` тогда будет:

```ini
host=localhost
port=5432
name=giraffic_db
```

### Вариант B: одна общая база на сервере

Подходит, если несколько людей должны работать с одними данными.

1. PostgreSQL стоит на сервере.
2. В PostgreSQL разрешены внешние подключения.
3. В `giraffic.ini` у пользователей указан IP или домен сервера:

```ini
host=192.168.1.50
port=5432
name=giraffic_db
```

Минус: надо настраивать безопасность, firewall, пароли, доступы и резервные копии.

## 4. Деплой на Windows

### 4.1. Собрать Release

В Qt Creator:

1. Открой проект.
2. Слева выбери `Projects`.
3. Выбери Desktop Qt MinGW kit.
4. Переключи сборку на `Release`.
5. Нажми `Build`.

После сборки должен появиться файл:

```text
build/.../appQMLGiraffic.exe
```

### 4.2. Собрать папку для передачи пользователю

В PowerShell из корня проекта:

```powershell
.\scripts\deploy-windows.ps1
```

Скрипт:

- создаст папку `dist/windows`;
- скопирует туда `appQMLGiraffic.exe`;
- запустит `windeployqt`;
- положит рядом `giraffic.ini.example`.

Если build-папка называется иначе, передай путь явно:

```powershell
.\scripts\deploy-windows.ps1 -BuildDir "build/Desktop_Qt_6_10_2_MinGW_64_bit-u041eu0442u043bu0430u0434u043au0430" -DeployDir "dist/windows"
```

### 4.3. Добавить настройки базы

В папке `dist/windows`:

1. Скопируй `giraffic.ini.example`.
2. Переименуй копию в `giraffic.ini`.
3. Проверь host/port/name/users/passwords.

Структура папки должна быть примерно такая:

```text
dist/windows/
  appQMLGiraffic.exe
  giraffic.ini
  Qt6Core.dll
  Qt6Gui.dll
  Qt6Qml.dll
  Qt6Quick.dll
  sqldrivers/
  qml/
  platforms/
```

### 4.4. Проверить PostgreSQL-драйвер

Так как приложение использует `QPSQL`, в папке деплоя должен быть драйвер:

```text
dist/windows/sqldrivers/qsqlpsql.dll
```

Если приложение на чужом ПК пишет, что драйвер PostgreSQL не загружен, проверь наличие:

- `sqldrivers/qsqlpsql.dll`;
- `libpq.dll`;
- зависимостей `libpq.dll`, например `libssl*.dll`, `libcrypto*.dll`, `libintl*.dll`, `libiconv*.dll`, если они нужны твоей сборке PostgreSQL/Qt.

Часто проще поставить PostgreSQL на компьютер пользователя и добавить его `bin` в `PATH`, но для красивого деплоя лучше копировать нужные DLL рядом с `.exe`.

### 4.5. Передать пользователю

Передавать надо всю папку `dist/windows`, а не только `.exe`.

Пользователь запускает:

```text
appQMLGiraffic.exe
```

## 5. Деплой на macOS

Важно: macOS-приложение надо собирать на macOS. С Windows нормальный `.app` для Mac не собрать.

### 5.1. Собрать Release на Mac

1. Установи Qt для macOS.
2. Открой проект в Qt Creator на Mac.
3. Выбери Release.
4. Собери проект.

На выходе будет:

```text
appQMLGiraffic.app
```

### 5.2. Запустить macdeployqt

В терминале на Mac:

```bash
macdeployqt path/to/appQMLGiraffic.app -qmldir=. -dmg
```

Или через скрипт:

```bash
chmod +x scripts/deploy-macos.sh
./scripts/deploy-macos.sh path/to/appQMLGiraffic.app .
```

Скрипт создаст `.dmg`, который можно передать пользователю.

### 5.3. Куда положить giraffic.ini на macOS

Самый простой вариант для теста: положить `giraffic.ini` рядом с исполняемым файлом внутри bundle:

```text
appQMLGiraffic.app/Contents/MacOS/giraffic.ini
```

То есть:

```bash
cp config/giraffic.ini.example appQMLGiraffic.app/Contents/MacOS/giraffic.ini
```

Потом открыть файл и поменять параметры базы.

### 5.4. PostgreSQL на Mac

Если у пользователя своя локальная база:

1. Установить PostgreSQL.
2. Создать `giraffic_db`.
3. Накатить SQL-дамп.
4. Проверить роли и пароли.
5. Запустить `.app`.

## 6. Иконка приложения

Иконка уже подключена:

- `assets/app_icon.png` используется приложением во время запуска.
- `assets/app_icon.ico` вшивается в Windows `.exe` через `app_icon.rc`.
- `assets/app_icon.icns` попадает в macOS `.app`.

Чтобы заменить иконку:

1. Подготовь новые файлы с такими же именами.
2. Положи их в папку `assets`.
3. Пересобери проект.

## 7. GitHub

В репозиторий надо класть:

- исходники `.cpp/.h/.qml`;
- `CMakeLists.txt`;
- `assets/app_icon.*`;
- `config/giraffic.ini.example`;
- `scripts/`;
- `DEPLOY.md`.

Не надо класть:

- `build/`;
- `dist/`;
- реальный `giraffic.ini` с паролями;
- локальные настройки Qt Creator.
