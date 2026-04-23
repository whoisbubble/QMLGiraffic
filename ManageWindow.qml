import QtQuick
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: manageWin

    width: 1240
    height: 760
    minimumWidth: 1120
    minimumHeight: 640
    title: "Giraffic - Workspace"
    flags: Qt.Window | Qt.FramelessWindowHint
    color: "transparent"
    visible: true

    AppTheme { id: theme }
    NotifyWindow { id: notifyDialog }

    property string currentRole: dbManager.currentUserRole.toString().toLowerCase()
    property bool isAdmin: currentRole === "admin" || currentRole === "giraffic_admin"
    property bool isManager: currentRole.indexOf("manager") !== -1 || isAdmin
    property bool isGuest: !isManager && !isAdmin

    property var workersData: []
    property var rolesData: []
    property var eventsData: []
    property int selectedEventId: -1
    property var loginWindow: null

    function refreshAll() {
        eventsData = dbManager.getEventsList(filterFrom.text, filterTo.text)
        if (manageWin.isGuest) {
            workersData = []
            rolesData = []
            return
        }

        workersData = dbManager.getWorkersList()
        rolesData = dbManager.getRolesList()
    }

    function openWindow(fileName, options) {
        var component = Qt.createComponent(fileName)
        if (component.status === Component.Ready) {
            var initialProperties = options || {}
            initialProperties.visible = true
            if (!component.createObject(manageWin, initialProperties)) {
                notifyDialog.showMsg("Ошибка QML", "Не удалось открыть окно.")
            } else {
                return
            }
        } else {
            notifyDialog.showMsg("Ошибка QML", component.errorString())
        }
    }

    Component.onCompleted: {
        refreshAll()
    }

    Rectangle {
        id: shell
        anchors.fill: parent
        anchors.margins: 10
        radius: 8
        color: theme.ink
        border.color: theme.line
        border.width: 1
        clip: true

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#212b24" }
            GradientStop { position: 0.55; color: theme.shell }
            GradientStop { position: 1.0; color: "#101412" }
        }

        GiraffePattern {
            anchors.fill: parent
            strength: 0.09
        }

        MouseArea { width: 6; anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom; cursorShape: Qt.SizeHorCursor; onPressed: manageWin.startSystemResize(Qt.RightEdge) }
        MouseArea { height: 6; anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; cursorShape: Qt.SizeVerCursor; onPressed: manageWin.startSystemResize(Qt.BottomEdge) }
        MouseArea { width: 18; height: 18; anchors.right: parent.right; anchors.bottom: parent.bottom; cursorShape: Qt.SizeFDiagCursor; onPressed: manageWin.startSystemResize(Qt.RightEdge | Qt.BottomEdge) }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 66

                MouseArea {
                    anchors.fill: parent
                    onPressed: manageWin.startSystemMove()
                }

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 22
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    Rectangle {
                        width: 38
                        height: 38
                        radius: 8
                        color: theme.amber

                        Text {
                            anchors.centerIn: parent
                            text: "G"
                            color: theme.ink
                            font.bold: true
                            font.pixelSize: 23
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        Text {
                            text: "Giraffic Control"
                            color: theme.text
                            font.bold: true
                            font.pixelSize: 17
                        }

                        Text {
                            text: "мероприятия, люди, площадки"
                            color: theme.muted
                            font.pixelSize: 11
                        }
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    Rectangle {
                        height: 30
                        width: roleText.implicitWidth + 24
                        radius: 8
                        color: manageWin.isAdmin ? Qt.rgba(231 / 255, 91 / 255, 91 / 255, 0.16)
                                                  : (manageWin.isManager ? Qt.rgba(84 / 255, 209 / 255, 122 / 255, 0.16)
                                                                         : Qt.rgba(154 / 255, 167 / 255, 154 / 255, 0.16))
                        border.color: manageWin.isAdmin ? theme.danger : (manageWin.isManager ? theme.leaf : theme.line)

                        Text {
                            id: roleText
                            anchors.centerIn: parent
                            text: dbManager.currentUserRole
                            color: manageWin.isAdmin ? theme.danger : (manageWin.isManager ? theme.leaf : theme.muted)
                            font.bold: true
                            font.pixelSize: 12
                        }
                    }

                    AppButton {
                        width: 82
                        height: 30
                        text: "Выйти"
                        variant: "ghost"
                        onClicked: {
                            dbManager.logoutUser()
                            var component = Qt.createComponent("Main.qml")
                            if (component.status === Component.Ready) {
                                manageWin.loginWindow = component.createObject(null)
                                if (manageWin.loginWindow) {
                                    manageWin.loginWindow.show()
                                    manageWin.close()
                                } else {
                                    notifyDialog.showMsg("Ошибка QML", "Не удалось открыть окно входа.")
                                }
                            } else {
                                notifyDialog.showMsg("Ошибка QML", component.errorString())
                            }
                        }
                    }

                    Rectangle {
                        width: 13
                        height: 13
                        radius: 7
                        color: minArea.containsMouse ? theme.amberSoft : theme.amber
                        anchors.verticalCenter: parent.verticalCenter
                        MouseArea { id: minArea; anchors.fill: parent; hoverEnabled: true; onClicked: manageWin.showMinimized() }
                    }

                    Rectangle {
                        width: 13
                        height: 13
                        radius: 7
                        color: closeArea.containsMouse ? "#ff8080" : theme.danger
                        anchors.verticalCenter: parent.verticalCenter
                        MouseArea { id: closeArea; anchors.fill: parent; hoverEnabled: true; onClicked: manageWin.close() }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: theme.line }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Rectangle {
                    anchors.centerIn: parent
                    width: 430
                    height: 150
                    radius: 8
                    color: theme.surface
                    border.color: theme.danger
                    z: 10
                    visible: false

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: "Доступ закрыт"
                            color: theme.danger
                            font.pixelSize: 24
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: "У вас права гостя. Попросите администратора назначить роль."
                            color: theme.muted
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                            Layout.preferredWidth: 340
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 16
                    enabled: true
                    opacity: 1.0

                    AppPanel {
                        Layout.fillHeight: true
                        Layout.fillWidth: manageWin.isGuest
                        Layout.preferredWidth: Math.max(660, parent.width * 0.64)
                        title: "Лента мероприятий"
                        subtitle: "Фильтр, просмотр и быстрые действия"
                        accent: theme.amber

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 14

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                AppField {
                                    id: filterFrom
                                    placeholderText: "От: ДД.ММ.ГГГГ"
                                    text: Qt.formatDate(new Date(), "dd.MM.yyyy")
                                    Layout.preferredWidth: 142
                                    onEditingFinished: manageWin.refreshAll()
                                }

                                AppField {
                                    id: filterTo
                                    placeholderText: "До: ДД.ММ.ГГГГ"
                                    Layout.preferredWidth: 142
                                    onEditingFinished: manageWin.refreshAll()
                                }

                                Item { Layout.fillWidth: true }

                                AppButton {
                                    text: "Копировать"
                                    variant: "blue"
                                    visible: !manageWin.isGuest
                                    Layout.preferredWidth: 132
                                    onClicked: {
                                        var textToCopy = dbManager.getAllEventsText(filterFrom.text, filterTo.text)
                                        dbManager.copyToClipboard(textToCopy)
                                        notifyDialog.showMsg("Успех", "Список мероприятий скопирован в буфер обмена.")
                                    }
                                }

                                AppButton {
                                    text: "Новое"
                                    variant: "green"
                                    visible: !manageWin.isGuest
                                    Layout.preferredWidth: 100
                                    onClicked: manageWin.openWindow("AddEventWindow.qml", { "owner": manageWin })
                                }

                                AppButton {
                                    text: "Обновить"
                                    variant: "ghost"
                                    Layout.preferredWidth: 106
                                    onClicked: manageWin.refreshAll()
                                }
                            }

                            ListView {
                                id: eventsList
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                spacing: 10
                                model: manageWin.eventsData

                                delegate: Rectangle {
                                    property int assignedCount: Number(modelData.assignedCount || 0)
                                    property bool underStaffed: assignedCount < 3

                                    width: eventsList.width
                                    height: 76
                                    radius: 8
                                    color: manageWin.selectedEventId === modelData.id ? Qt.rgba(245 / 255, 200 / 255, 75 / 255, 0.18)
                                                                                      : (underStaffed ? Qt.rgba(231 / 255, 91 / 255, 91 / 255, 0.13)
                                                                                                      : (eventMouseArea.containsMouse ? theme.surfaceHigh : "#1d241f"))
                                    border.color: underStaffed ? theme.danger : (manageWin.selectedEventId === modelData.id ? theme.amber : theme.line)
                                    border.width: 1

                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        height: 3
                                        color: theme.danger
                                        visible: underStaffed
                                    }

                                    RowLayout {
                                        z: 1
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 12

                                        Rectangle {
                                            Layout.preferredWidth: 46
                                            Layout.preferredHeight: 46
                                            radius: 8
                                            color: manageWin.selectedEventId === modelData.id ? theme.amber : theme.surface
                                            border.color: theme.line

                                            Text {
                                                anchors.centerIn: parent
                                                text: "S"
                                                color: manageWin.selectedEventId === modelData.id ? theme.ink : theme.amber
                                                font.bold: true
                                                font.pixelSize: 20
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 4

                                            Text {
                                                text: modelData.title
                                                color: theme.text
                                                font.bold: true
                                                font.pixelSize: 15
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                            Text {
                                                text: "Дата: " + modelData.date
                                                color: theme.muted
                                                font.pixelSize: 12
                                            }

                                            Text {
                                                text: "Назначено: " + assignedCount + "/3"
                                                visible: underStaffed
                                                color: theme.danger
                                                font.bold: true
                                                font.pixelSize: 11
                                            }
                                        }

                                        AppButton {
                                            text: "Инфо"
                                            variant: "blue"
                                            Layout.preferredWidth: 72
                                            onClicked: notifyDialog.showMsg("Информация", dbManager.getEventDetailsString(modelData.id))
                                        }
                                    }

                                    MouseArea {
                                        id: eventMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        z: 0
                                        onClicked: manageWin.selectedEventId = modelData.id
                                    }
                                }
                            }
                        }
                    }

                    AppPanel {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        visible: !manageWin.isGuest
                        title: "Команда на смену"
                        subtitle: manageWin.selectedEventId === -1 ? "Выберите мероприятие слева" : "Мероприятие ID: " + manageWin.selectedEventId
                        accent: manageWin.selectedEventId === -1 ? theme.danger : theme.leaf

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 14

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 82
                                radius: 8
                                color: "#1d241f"
                                border.color: theme.line

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 3

                                    Text {
                                        text: manageWin.selectedEventId === -1 ? "Смена не выбрана" : "Смена выбрана"
                                        color: manageWin.selectedEventId === -1 ? theme.danger : theme.leaf
                                        font.bold: true
                                        font.pixelSize: 18
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }

                                    Text {
                                        text: manageWin.selectedEventId === -1 ? "Кликните по карточке мероприятия" : "Теперь назначьте сотрудника и роль"
                                        color: theme.muted
                                        font.pixelSize: 12
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }
                            }

                            AppComboBox {
                                id: workerCombo
                                Layout.fillWidth: true
                                model: manageWin.workersData
                                textRole: "text"
                                valueRole: "value"
                            }

                            AppComboBox {
                                id: roleCombo
                                Layout.fillWidth: true
                                model: manageWin.rolesData
                                textRole: "text"
                                valueRole: "value"
                            }

                            AppField {
                                id: payInput
                                placeholderText: "Оплата работнику, руб"
                                Layout.fillWidth: true
                                validator: RegularExpressionValidator { regularExpression: /^[0-9]+(\.[0-9]{1,2})?$/ }
                            }

                            AppButton {
                                text: "Назначить на смену"
                                enabled: manageWin.selectedEventId !== -1
                                Layout.fillWidth: true
                                onClicked: {
                                    if (payInput.text === "") {
                                        notifyDialog.showMsg("Ошибка", "Введите сумму.")
                                        return
                                    }

                                    if (dbManager.assignWorker(manageWin.selectedEventId, workerCombo.currentValue, roleCombo.currentValue, parseFloat(payInput.text))) {
                                        notifyDialog.showMsg("Успех", "Работник добавлен.")
                                        payInput.text = ""
                                        manageWin.refreshAll()
                                    } else {
                                        notifyDialog.showMsg("Ошибка", dbManager.lastError)
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 1
                                color: theme.line
                            }

                            Text {
                                text: "Справочники"
                                color: theme.muted
                                font.pixelSize: 12
                                font.bold: true
                            }

                            GridLayout {
                                Layout.fillWidth: true
                                columns: 2
                                columnSpacing: 10
                                rowSpacing: 10

                                AppButton {
                                    text: "Сотрудники"
                                    variant: "ghost"
                                    Layout.fillWidth: true
                                    onClicked: manageWin.openWindow("WorkersWindow.qml", { "owner": manageWin })
                                }

                                AppButton {
                                    text: "Площадки"
                                    variant: "ghost"
                                    Layout.fillWidth: true
                                    onClicked: manageWin.openWindow("VenuesWindow.qml")
                                }

                                AppButton {
                                    text: "Клиенты"
                                    variant: "ghost"
                                    Layout.fillWidth: true
                                    onClicked: manageWin.openWindow("ClientsWindow.qml")
                                }

                                AppButton {
                                    text: "Админ"
                                    variant: "danger"
                                    visible: manageWin.isAdmin
                                    Layout.fillWidth: true
                                    onClicked: manageWin.openWindow("AdminWindow.qml", { "owner": manageWin })
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
