import QtQuick
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: mainWindow

    width: 430
    height: 620
    minimumWidth: 390
    minimumHeight: 560
    visible: true
    title: "Giraffic Login"
    flags: Qt.Window | Qt.FramelessWindowHint
    color: "transparent"

    AppTheme { id: theme }
    NotifyWindow { id: notifyDialog }

    property var workspaceWindow: null

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
            GradientStop { position: 0.0; color: "#253127" }
            GradientStop { position: 0.58; color: theme.shell }
            GradientStop { position: 1.0; color: "#111513" }
        }

        GiraffePattern {
            anchors.fill: parent
            strength: 0.13
        }

        MouseArea { width: 6; anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom; cursorShape: Qt.SizeHorCursor; onPressed: mainWindow.startSystemResize(Qt.RightEdge) }
        MouseArea { height: 6; anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; cursorShape: Qt.SizeVerCursor; onPressed: mainWindow.startSystemResize(Qt.BottomEdge) }
        MouseArea { width: 18; height: 18; anchors.right: parent.right; anchors.bottom: parent.bottom; cursorShape: Qt.SizeFDiagCursor; onPressed: mainWindow.startSystemResize(Qt.RightEdge | Qt.BottomEdge) }

        Item {
            id: titleBar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 48

            MouseArea {
                anchors.fill: parent
                onPressed: mainWindow.startSystemMove()
            }

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Rectangle {
                    width: 30
                    height: 30
                    radius: 8
                    color: theme.amber

                    Text {
                        anchors.centerIn: parent
                        text: "G"
                        color: theme.ink
                        font.bold: true
                        font.pixelSize: 18
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0

                    Text {
                        text: "GIRAFFIC"
                        color: theme.text
                        font.bold: true
                        font.pixelSize: 13
                    }

                    Text {
                        text: "рабочие графики"
                        color: theme.muted
                        font.pixelSize: 10
                    }
                }
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Rectangle {
                    width: 13
                    height: 13
                    radius: 7
                    color: minArea.containsMouse ? theme.amberSoft : theme.amber
                    MouseArea { id: minArea; anchors.fill: parent; hoverEnabled: true; onClicked: mainWindow.showMinimized() }
                }

                Rectangle {
                    width: 13
                    height: 13
                    radius: 7
                    color: closeArea.containsMouse ? "#ff8080" : theme.danger
                    MouseArea { id: closeArea; anchors.fill: parent; hoverEnabled: true; onClicked: mainWindow.close() }
                }
            }
        }

        ColumnLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: titleBar.bottom
            anchors.bottom: parent.bottom
            anchors.margins: 28
            anchors.topMargin: 18
            spacing: 18

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 128

                Rectangle {
                    width: 118
                    height: 118
                    radius: 8
                    anchors.centerIn: parent
                    color: Qt.rgba(245 / 255, 200 / 255, 75 / 255, 0.12)
                    border.color: Qt.rgba(245 / 255, 200 / 255, 75 / 255, 0.35)

                    Text {
                        anchors.centerIn: parent
                        text: "G"
                        color: theme.amber
                        font.bold: true
                        font.pixelSize: 74
                    }

                    GiraffePattern {
                        anchors.fill: parent
                        strength: 0.28
                    }
                }
            }

            StackLayout {
                id: viewStack
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: 0

                ColumnLayout {
                    spacing: 14

                    Text {
                        text: "Вход в смены"
                        color: theme.text
                        font.bold: true
                        font.pixelSize: 25
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "Планируйте мероприятия, команды и занятость персонала"
                        color: theme.muted
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    AppField {
                        id: loginField
                        placeholderText: "Логин"
                        maximumLength: 50
                        Layout.fillWidth: true
                    }

                    AppField {
                        id: passField
                        placeholderText: "Пароль"
                        echoMode: TextInput.Password
                        maximumLength: 50
                        Layout.fillWidth: true
                    }

                    AppButton {
                        text: "Войти"
                        Layout.fillWidth: true
                        onClicked: {
                            if (dbManager.loginUser(loginField.text, passField.text)) {
                                var component = Qt.createComponent("ManageWindow.qml")
                                if (component.status === Component.Ready) {
                                    mainWindow.workspaceWindow = component.createObject(null)
                                    if (mainWindow.workspaceWindow) {
                                        mainWindow.workspaceWindow.show()
                                        mainWindow.close()
                                    } else {
                                        notifyDialog.showMsg("Ошибка QML", "Не удалось открыть рабочее окно.")
                                    }
                                } else {
                                    notifyDialog.showMsg("Ошибка QML", component.errorString())
                                }
                            } else {
                                notifyDialog.showMsg("Ошибка входа", dbManager.lastError)
                            }
                        }
                    }

                    Text {
                        text: "Нет аккаунта? Зарегистрироваться"
                        color: registerLink.containsMouse ? theme.amber : theme.muted
                        font.pixelSize: 13
                        Layout.alignment: Qt.AlignHCenter

                        MouseArea {
                            id: registerLink
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: viewStack.currentIndex = 1
                        }
                    }
                }

                ColumnLayout {
                    spacing: 14

                    Text {
                        text: "Новый аккаунт"
                        color: theme.text
                        font.bold: true
                        font.pixelSize: 25
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "Создайте профиль и дождитесь назначения роли"
                        color: theme.muted
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    AppField {
                        id: regLoginField
                        placeholderText: "Придумайте логин"
                        maximumLength: 50
                        Layout.fillWidth: true
                    }

                    AppField {
                        id: regPassField
                        placeholderText: "Пароль"
                        echoMode: TextInput.Password
                        maximumLength: 50
                        Layout.fillWidth: true
                    }

                    AppButton {
                        text: "Создать аккаунт"
                        variant: "green"
                        Layout.fillWidth: true
                        onClicked: {
                            if (dbManager.registerUser(regLoginField.text, regPassField.text)) {
                                notifyDialog.showMsg("Успех", "Аккаунт создан! Теперь войдите.")
                                viewStack.currentIndex = 0
                            } else {
                                notifyDialog.showMsg("Ошибка регистрации", dbManager.lastError)
                            }
                        }
                    }

                    Text {
                        text: "Назад ко входу"
                        color: loginLink.containsMouse ? theme.amber : theme.muted
                        font.pixelSize: 13
                        Layout.alignment: Qt.AlignHCenter

                        MouseArea {
                            id: loginLink
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: viewStack.currentIndex = 0
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.preferredWidth: 10
                    Layout.preferredHeight: 10
                    radius: 5
                    color: dbManager.isConnected ? theme.leaf : theme.danger

                    SequentialAnimation on opacity {
                        running: !dbManager.isConnected
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.35; duration: 700 }
                        NumberAnimation { to: 1.0; duration: 700 }
                    }
                }

                Text {
                    text: dbManager.isConnected ? "База подключена" : "База недоступна"
                    color: dbManager.isConnected ? theme.muted : theme.danger
                    font.pixelSize: 12
                    Layout.fillWidth: true
                }

                Text {
                    text: "проверить"
                    color: dbStatusArea.containsMouse ? theme.amber : theme.muted
                    font.pixelSize: 12

                    MouseArea {
                        id: dbStatusArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!dbManager.isConnected) dbManager.connectToDatabase()
                            notifyDialog.showMsg("Статус БД", dbManager.lastError)
                        }
                    }
                }
            }
        }
    }
}
