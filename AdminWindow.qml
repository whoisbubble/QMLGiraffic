import QtQuick
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: adminWin

    width: 920
    height: 700
    minimumWidth: 840
    minimumHeight: 640
    title: "Админ панель"
    flags: Qt.Window | Qt.FramelessWindowHint
    color: "transparent"
    modality: Qt.ApplicationModal

    AppTheme { id: theme }
    NotifyWindow { id: notifyDialog }

    property var owner: null
    property int currentTab: 0
    property int currentLogPage: 1
    property int selectedRecordId: -1
    property var usersData: []
    property var rolesData: []
    property var recordsData: []
    property var auditData: []
    property var adminWorkersData: []
    property var adminVenuesData: []
    property var workerStatsData: []
    property string statsResult: "Выберите параметры и нажмите нужную кнопку."

    function selectedMonth() {
        var month = parseInt(statsMonthField.text)
        return isNaN(month) || month < 1 || month > 12 ? new Date().getMonth() + 1 : month
    }

    function selectedYear() {
        var year = parseInt(statsYearField.text)
        return isNaN(year) || year < 2000 ? new Date().getFullYear() : year
    }

    function loadRecords() {
        recordsData = dbManager.getTableRecords(tableCombo.currentValue)
        selectedRecordId = -1
    }

    function loadAudit() {
        var type = auditCombo.currentValue ? auditCombo.currentValue : "login_audit"
        auditData = dbManager.getAuditLogs(type, currentLogPage)
    }

    function refreshAdminData() {
        usersData = dbManager.getAppUsersList()
        rolesData = dbManager.getAppRolesList()
        adminWorkersData = dbManager.getWorkersList()
        adminVenuesData = dbManager.getVenuesList()
        loadRecords()
        loadAudit()
    }

    function showCompanyEfficiency() {
        var value = dbManager.getCompanyEfficiency(selectedMonth(), selectedYear())
        statsResult = "KPI компании за " + selectedMonth() + "." + selectedYear() + ": " + value.toFixed(2) + "%"
    }

    function showVenuePopularity() {
        if (venueStatsCombo.count === 0) {
            statsResult = "Нет площадок для расчета."
            return
        }

        var value = dbManager.getVenuePopularity(venueStatsCombo.currentValue)
        statsResult = "Популярность площадки: " + value + " мероприятий."
    }

    function showWorkerBonus() {
        if (workerStatsCombo.count === 0) {
            statsResult = "Нет сотрудников для расчета."
            return
        }

        var value = dbManager.getWorkerBonus(workerStatsCombo.currentValue, selectedMonth(), selectedYear())
        statsResult = "Бонус сотрудника за " + selectedMonth() + "." + selectedYear() + ": " + value.toFixed(2) + " руб."
    }

    function showWorkerStats() {
        if (workerStatsCombo.count === 0) {
            statsResult = "Нет сотрудников для расчета."
            workerStatsData = []
            return
        }

        workerStatsData = dbManager.getWorkerStats(workerStatsCombo.currentValue)
        statsResult = workerStatsData.length === 0 ? "По выбранному сотруднику пока нет назначений."
                                                   : "Статистика сотрудника по месяцам загружена."
    }

    Component.onCompleted: refreshAdminData()

    Rectangle {
        anchors.fill: parent
        anchors.margins: 10
        radius: 8
        color: theme.ink
        border.color: theme.danger
        clip: true

        GiraffePattern {
            anchors.fill: parent
            strength: 0.08
            spotColor: theme.danger
        }

        Item {
            id: titleBar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 58

            MouseArea {
                anchors.fill: parent
                onPressed: adminWin.startSystemMove()
            }

            Text {
                text: "Админ панель"
                color: theme.text
                font.bold: true
                font.pixelSize: 18
                anchors.left: parent.left
                anchors.leftMargin: 22
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: 13
                height: 13
                radius: 7
                color: closeArea.containsMouse ? "#ff8080" : theme.danger
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: adminWin.close()
                }
            }
        }

        ColumnLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: titleBar.bottom
            anchors.bottom: parent.bottom
            anchors.margins: 18
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                AppButton {
                    text: "Права и роли"
                    variant: adminWin.currentTab === 0 ? "danger" : "ghost"
                    Layout.fillWidth: true
                    onClicked: adminWin.currentTab = 0
                }

                AppButton {
                    text: "Удаление данных"
                    variant: adminWin.currentTab === 1 ? "danger" : "ghost"
                    Layout.fillWidth: true
                    onClicked: {
                        adminWin.currentTab = 1
                        adminWin.loadRecords()
                    }
                }

                AppButton {
                    text: "Журнал аудита"
                    variant: adminWin.currentTab === 2 ? "danger" : "ghost"
                    Layout.fillWidth: true
                    onClicked: {
                        adminWin.currentTab = 2
                        adminWin.loadAudit()
                    }
                }

                AppButton {
                    text: "Статистика"
                    variant: adminWin.currentTab === 3 ? "danger" : "ghost"
                    Layout.fillWidth: true
                    onClicked: adminWin.currentTab = 3
                }
            }

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: adminWin.currentTab

                AppPanel {
                    title: "Назначение роли"
                    subtitle: "Выберите пользователя и роль приложения"
                    accent: theme.danger

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 12

                        AppComboBox {
                            id: userCombo
                            Layout.fillWidth: true
                            model: adminWin.usersData
                            textRole: "text"
                            valueRole: "value"
                        }

                        AppComboBox {
                            id: roleCombo
                            Layout.fillWidth: true
                            model: adminWin.rolesData
                            textRole: "text"
                            valueRole: "value"
                        }

                        AppButton {
                            text: "Назначить роль"
                            variant: "danger"
                            Layout.fillWidth: true
                            onClicked: {
                                if (dbManager.assignAppUserRole(userCombo.currentValue, roleCombo.currentValue)) {
                                    notifyDialog.showMsg("Успех", "Роль успешно назначена.")
                                } else {
                                    notifyDialog.showMsg("Ошибка БД", dbManager.lastError)
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }

                AppPanel {
                    title: "Опасная зона"
                    subtitle: "Точечное удаление записей"
                    accent: theme.danger

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            AppComboBox {
                                id: tableCombo
                                Layout.fillWidth: true
                                textRole: "text"
                                valueRole: "value"
                                model: ListModel {
                                    ListElement { text: "Мероприятия"; value: "events" }
                                    ListElement { text: "Сотрудники"; value: "workers" }
                                    ListElement { text: "Клиенты"; value: "clients" }
                                    ListElement { text: "Площадки"; value: "venues" }
                                    ListElement { text: "Пользователи приложения"; value: "app_users" }
                                }
                                onActivated: adminWin.loadRecords()
                            }

                            AppButton {
                                text: "Загрузить"
                                variant: "ghost"
                                Layout.preferredWidth: 110
                                onClicked: adminWin.loadRecords()
                            }
                        }

                        ListView {
                            id: recordsList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 8
                            model: adminWin.recordsData

                            delegate: Rectangle {
                                width: recordsList.width
                                height: 48
                                radius: 8
                                color: adminWin.selectedRecordId === modelData.value ? Qt.rgba(231 / 255, 91 / 255, 91 / 255, 0.18) : "#1d241f"
                                border.color: adminWin.selectedRecordId === modelData.value ? theme.danger : theme.line

                                Text {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 14
                                    text: modelData.text
                                    color: theme.text
                                    font.pixelSize: 14
                                    elide: Text.ElideRight
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: adminWin.selectedRecordId = modelData.value
                                }
                            }
                        }

                        AppButton {
                            text: "Удалить выбранную запись"
                            variant: "danger"
                            enabled: adminWin.selectedRecordId !== -1
                            Layout.fillWidth: true
                            onClicked: {
                                if (dbManager.deleteRecord(tableCombo.currentValue, adminWin.selectedRecordId)) {
                                    notifyDialog.showMsg("Успех", "Запись удалена.")
                                    adminWin.loadRecords()
                                    if (adminWin.owner && adminWin.owner.refreshAll) {
                                        adminWin.owner.refreshAll()
                                    }
                                } else {
                                    notifyDialog.showMsg("Ошибка БД", dbManager.lastError)
                                }
                            }
                        }
                    }
                }

                AppPanel {
                    title: "Журнал аудита"
                    subtitle: "История входов и изменений"
                    accent: theme.danger

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            AppComboBox {
                                id: auditCombo
                                Layout.fillWidth: true
                                textRole: "text"
                                valueRole: "value"
                                model: ListModel {
                                    ListElement { text: "Входы в систему"; value: "login_audit" }
                                    ListElement { text: "Изменения таблиц (DDL)"; value: "audit_ddl" }
                                    ListElement { text: "Действия с данными (DML)"; value: "audit_dml" }
                                }
                                onActivated: {
                                    adminWin.currentLogPage = 1
                                    adminWin.loadAudit()
                                }
                            }

                            AppButton {
                                text: "Очистить"
                                variant: "danger"
                                Layout.preferredWidth: 110
                                onClicked: {
                                    dbManager.clearTable(auditCombo.currentValue)
                                    adminWin.currentLogPage = 1
                                    adminWin.loadAudit()
                                }
                            }
                        }

                        ListView {
                            id: auditList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 8
                            model: adminWin.auditData

                            delegate: Rectangle {
                                width: auditList.width
                                height: 44
                                radius: 8
                                color: "#1d241f"
                                border.color: theme.line

                                Text {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 14
                                    text: modelData.logText
                                    color: theme.text
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            AppButton {
                                text: "Назад"
                                variant: "ghost"
                                enabled: adminWin.currentLogPage > 1
                                Layout.preferredWidth: 100
                                onClicked: {
                                    adminWin.currentLogPage--
                                    adminWin.loadAudit()
                                }
                            }

                            Text {
                                text: "Страница " + adminWin.currentLogPage
                                color: theme.amber
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                Layout.fillWidth: true
                            }

                            AppButton {
                                text: "Вперед"
                                variant: "ghost"
                                enabled: adminWin.auditData.length >= 10
                                Layout.preferredWidth: 100
                                onClicked: {
                                    adminWin.currentLogPage++
                                    adminWin.loadAudit()
                                }
                            }
                        }
                    }
                }

                AppPanel {
                    title: "Статистика"
                    subtitle: "Безопасные запросы к функциям базы данных"
                    accent: theme.amber

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            AppField {
                                id: statsMonthField
                                text: String(new Date().getMonth() + 1)
                                placeholderText: "Месяц"
                                validator: RegularExpressionValidator { regularExpression: /^([1-9]|1[0-2])$/ }
                                Layout.preferredWidth: 92
                            }

                            AppField {
                                id: statsYearField
                                text: String(new Date().getFullYear())
                                placeholderText: "Год"
                                validator: RegularExpressionValidator { regularExpression: /^[0-9]{4}$/ }
                                Layout.preferredWidth: 110
                            }

                            AppButton {
                                text: "KPI компании"
                                variant: "blue"
                                Layout.fillWidth: true
                                onClicked: adminWin.showCompanyEfficiency()
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            AppComboBox {
                                id: venueStatsCombo
                                Layout.fillWidth: true
                                model: adminWin.adminVenuesData
                                textRole: "text"
                                valueRole: "value"
                            }

                            AppButton {
                                text: "Популярность"
                                variant: "ghost"
                                Layout.preferredWidth: 150
                                onClicked: adminWin.showVenuePopularity()
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            AppComboBox {
                                id: workerStatsCombo
                                Layout.fillWidth: true
                                model: adminWin.adminWorkersData
                                textRole: "text"
                                valueRole: "value"
                            }

                            AppButton {
                                text: "Бонус"
                                variant: "green"
                                Layout.preferredWidth: 110
                                onClicked: adminWin.showWorkerBonus()
                            }

                            AppButton {
                                text: "Месяцы"
                                variant: "ghost"
                                Layout.preferredWidth: 110
                                onClicked: adminWin.showWorkerStats()
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 78
                            radius: 8
                            color: "#1d241f"
                            border.color: theme.line

                            Text {
                                anchors.fill: parent
                                anchors.margins: 14
                                text: adminWin.statsResult
                                color: theme.text
                                font.pixelSize: 14
                                wrapMode: Text.WordWrap
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        ListView {
                            id: workerStatsList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 8
                            model: adminWin.workerStatsData

                            delegate: Rectangle {
                                width: workerStatsList.width
                                height: 42
                                radius: 8
                                color: "#1d241f"
                                border.color: theme.line

                                Text {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 14
                                    text: "Месяц " + modelData.month_num + ": " + modelData.work_count + " назначений"
                                    color: theme.text
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
