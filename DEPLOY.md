# Giraffic: деплой и использование

Этот файл объясняет:

- как настраивается база
- как работает локальный деплой
- как собирать macOS и Linux через GitHub Actions
- куда класть `giraffic.ini`
- что ожидать от каждой платформы

## 1. Как работает конфиг

Приложение читает настройки базы в таком порядке:

1. `GIRAFFIC_CONFIG_PATH`
2. системная папка конфигов приложения
3. `giraffic.ini` рядом с исполняемым файлом
4. текущая рабочая папка

Формат конфига:

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

Файл-пример:

```text
config/giraffic.ini.example
```

## 2. Куда класть `giraffic.ini`

### Windows

Рекомендуемый вариант:

```text
dist/windows/giraffic.ini
```

Либо можно явно указать путь:

```powershell
$env:GIRAFFIC_CONFIG_PATH = "C:\path\to\giraffic.ini"
```

### macOS

Лучший вариант:

```text
~/Library/Application Support/Giraffic/giraffic.ini
```

Быстрый тестовый вариант:

```text
Giraffic.app/Contents/MacOS/giraffic.ini
```

### Linux

Лучший вариант:

```text
~/.config/Giraffic/giraffic.ini
```

Либо так:

```bash
export GIRAFFIC_CONFIG_PATH="/path/to/giraffic.ini"
```

## 3. Локальный деплой на Windows

### 3.1. Сборка

Собери проект в `Release`.

На выходе должен получиться файл:

```text
build/.../Giraffic.exe
```

### 3.2. Деплой

Запуск:

```powershell
.\scripts\deploy-windows.ps1
```

Если нужно указать пути явно:

```powershell
.\scripts\deploy-windows.ps1 `
  -BuildDir "build/Desktop_Qt_6_10_2_MinGW_64_bit-u041eu0442u043bu0430u0434u043au0430" `
  -DeployDir "dist/windows" `
  -QtDir "C:/Qt/6.10.2/mingw_64"
```

Если PostgreSQL установлен не в стандартном месте:

```powershell
.\scripts\deploy-windows.ps1 -PostgresBin "C:\Program Files\PostgreSQL\18\bin"
```

### 3.3. Что получится

Примерно такая структура:

```text
dist/windows/
  Giraffic.exe
  giraffic.ini.example
  Qt*.dll
  libpq.dll
  sqldrivers/
  qml/
  platforms/
```

### 3.4. Что передавать пользователю

Нужно передавать **всю папку** `dist/windows`, а не только `.exe`.

## 4. Локальный деплой на macOS

Важно: нормальный `.app` нужно собирать именно на macOS.

### 4.1. Сборка

Собери проект в `Release`.

На выходе должен появиться:

```text
build/.../Giraffic.app
```

### 4.2. Деплой

Через скрипт:

```bash
chmod +x scripts/deploy-macos.sh
./scripts/deploy-macos.sh build/Release/Giraffic.app .
```

Если нужно пересобрать `assets/app_icon.icns` из PNG, сначала выполни:

```bash
chmod +x scripts/generate-macos-icon.sh
./scripts/generate-macos-icon.sh assets/app_icon.png assets/app_icon.icns
```

После этого используй `scripts/deploy-macos.sh`: он соберёт `.dmg`, в котором будут:

- `Giraffic.app`
- ярлык `Applications` для drag-and-drop установки
- `giraffic.ini.example`

### 4.3. Как пользователю настроить конфиг на Mac

Нормальный путь такой:

1. установить `Giraffic.app` в `/Applications`
2. создать папку:

```bash
mkdir -p ~/Library/Application\ Support/Giraffic
```

3. скопировать конфиг:

```bash
cp config/giraffic.ini.example ~/Library/Application\ Support/Giraffic/giraffic.ini
```

4. открыть `giraffic.ini` и вписать реальные параметры базы

### 4.4. Ограничения по старым Mac

Сейчас в проекте:

- GitHub Actions для macOS идут на `macos-15-intel`
- target выставлен на `macOS 11.0`
- используется Qt `6.5.3`

Это заметно лучше для старых Intel Mac, чем сборка под новый arm runner. Но если нужен запуск на очень старой macOS ниже `11`, то, скорее всего, придётся делать отдельную ветку на Qt 5.15.

## 5. Локальный деплой на Linux

### 5.1. Сборка

Собери проект в `Release`.

Ожидаемый бинарник:

```text
build-linux/Giraffic
```

### 5.2. Подготовка AppDir

Запуск:

```bash
chmod +x scripts/deploy-linux.sh
./scripts/deploy-linux.sh build-linux dist/linux/AppDir
```

Это создаст:

```text
dist/linux/AppDir
```

### 5.3. Упаковка

В GitHub Actions Linux-сборка пытается дополнительно собрать `AppImage` через `linuxdeploy`.

Linux — самая капризная платформа для деплоя из-за:

- различий между дистрибутивами
- версий OpenSSL
- совместимости `libpq`
- путей загрузки Qt plugins

Поэтому Linux-артефакт обязательно нужно проверять на реальной машине.

## 6. GitHub Actions

Workflow:

```text
.github/workflows/desktop-builds.yml
```

Он собирает:

- macOS на `macos-15-intel`
- Linux на `ubuntu-22.04`

## 7. Как запускать GitHub Actions

1. Запушь проект на GitHub.
2. Открой репозиторий.
3. Перейди во вкладку `Actions`.
4. Выбери `Desktop Builds`.
5. Нажми `Run workflow`.
6. Дождись завершения сборок.
7. Скачай артефакты:
   - `giraffic-macos`
   - `giraffic-linux`

## 8. Что лежит в артефактах

### macOS artifact

Обычно там:

- `Giraffic.app`
- `Giraffic.dmg`
- `giraffic.ini.example`

### Linux artifact

Обычно там:

- `AppDir`
- `.AppImage`

## 9. Имя приложения и свойства файла

Настраиваются в:

```text
CMakeLists.txt
cmake/windows_version.rc.in
cmake/Info.plist.in
```

Основные поля:

- имя приложения
- имя исполняемого файла
- описание
- компания
- copyright
- bundle identifier

Это влияет на:

- свойства файла на Windows
- имя `.app` на macOS
- имя бинарника
- пользовательское отображение приложения

## 10. Что нужно для PostgreSQL

Приложение использует `QPSQL`.

Значит, в деплое нужны:

- Qt SQL module
- Qt plugin PostgreSQL
- `libpq`
- связанные crypto/runtime библиотеки для нужной ОС

Типичная ошибка:

```text
Driver not loaded
```

Обычно это значит:

- не найден `qsqlpsql.dll` или `libqsqlpsql.so`
- не найден `libpq`
- не хватает OpenSSL-зависимостей

Обычно это **не** значит, что сломан `.ini`.

## 11. Как дать приложение другим людям

Есть два нормальных сценария.

### Вариант A: локальная база у каждого

Подходит для курсовой и демонстрации.

На каждом компьютере:

1. установить PostgreSQL
2. создать `giraffic_db`
3. импортировать твою схему и данные
4. создать роли БД
5. заполнить локальный `giraffic.ini`

### Вариант B: одна общая база на сервере

Подходит, если несколько людей работают с одними и теми же данными.

Пользователи:

1. получают приложение
2. получают `giraffic.ini`
3. подключаются к одному PostgreSQL серверу

Пример:

```ini
host=192.168.1.50
port=5432
name=giraffic_db
```

## 12. Права гостя

Если гость должен только смотреть мероприятия, можно выдать read-only права.

Пример:

```sql
GRANT USAGE ON SCHEMA giraffic TO giraffic_guest;

GRANT SELECT ON TABLE
    giraffic.events,
    giraffic.assignments,
    giraffic.workers,
    giraffic.roles,
    giraffic.clients,
    giraffic.venues
TO giraffic_guest;
```

Гостю не надо выдавать:

- `INSERT`
- `UPDATE`
- `DELETE`

## 13. Что коммитить, а что нет

Можно коммитить:

- исходники
- `CMakeLists.txt`
- `assets/app_icon.*`
- `config/giraffic.ini.example`
- `scripts/`
- `.github/workflows/`
- `README.md`
- `DEPLOY.md`

Не надо коммитить:

- реальный `giraffic.ini`
- пароли
- `build/`
- `dist/`
- локальные IDE-настройки

## 14. Практический совет

Для курсовой самый удобный и аккуратный путь такой:

1. в Git хранить только `giraffic.ini.example`
2. собирать артефакты через GitHub Actions
3. один раз тестировать каждый артефакт на реальной машине
4. пользователю отдавать:
   - готовый артефакт
   - короткую инструкцию, куда положить `giraffic.ini`
   - пример конфига

Это самый понятный, аккуратный и достаточно профессиональный вариант для твоего проекта.
