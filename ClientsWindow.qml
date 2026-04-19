import QtQuick
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: clientsWin

    width: 840
    height: 540
    title: "Клиенты"
    flags: Qt.Window | Qt.FramelessWindowHint
    color: "transparent"
    modality: Qt.ApplicationModal

    AppTheme { id: theme }
    NotifyWindow { id: notifyDialog }

    property var clientsList: dbManager.getClientsList()

    Rectangle {
        anchors.fill: parent
        anchors.margins: 10
        radius: 8
        color: theme.ink
        border.color: theme.line
        clip: true

        GiraffePattern {
            anchors.fill: parent
            strength: 0.08
        }

        Item {
            id: titleBar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 58

            MouseArea {
                anchors.fill: parent
                onPressed: clientsWin.startSystemMove()
            }

            Text {
                text: "Клиенты"
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
                color: closeCArea.containsMouse ? "#ff8080" : theme.danger
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                    id: closeCArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: clientsWin.close()
                }
            }
        }

        RowLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: titleBar.bottom
            anchors.bottom: parent.bottom
            anchors.margins: 18
            spacing: 16

            AppPanel {
                Layout.fillHeight: true
                Layout.preferredWidth: parent.width * 0.48
                title: "База клиентов"
                subtitle: "Компании и заказчики"
                accent: theme.sky

                ListView {
                    id: list
                    anchors.fill: parent
                    clip: true
                    spacing: 8
                    model: clientsWin.clientsList

                    delegate: Rectangle {
                        width: list.width
                        height: 48
                        radius: 8
                        color: "#1d241f"
                        border.color: theme.line

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
                    }
                }
            }

            AppPanel {
                Layout.fillHeight: true
                Layout.fillWidth: true
                title: "Новый клиент"
                subtitle: "Контакты и скидка"
                accent: theme.leaf

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 12

                    AppField {
                        id: cName
                        placeholderText: "Название компании"
                        Layout.fillWidth: true
                    }

                    AppField {
                        id: cPhone
                        placeholderText: "Телефон"
                        Layout.fillWidth: true
                    }

                    AppField {
                        id: cEmail
                        placeholderText: "Email"
                        Layout.fillWidth: true
                    }

                    AppField {
                        id: cDiscount
                        placeholderText: "Скидка, %"
                        Layout.fillWidth: true
                        validator: RegularExpressionValidator { regularExpression: /^[0-9]+$/ }
                    }

                    AppButton {
                        text: "Сохранить клиента"
                        variant: "green"
                        Layout.fillWidth: true
                        onClicked: {
                            if (cName.text === "") return
                            let disc = cDiscount.text === "" ? 0 : parseInt(cDiscount.text)
                            if (dbManager.addClient(cName.text, cPhone.text, cEmail.text, disc)) {
                                notifyDialog.showMsg("Успех", "Клиент добавлен.")
                                cName.text = ""
                                cPhone.text = ""
                                cEmail.text = ""
                                cDiscount.text = ""
                                clientsWin.clientsList = dbManager.getClientsList()
                            } else {
                                notifyDialog.showMsg("Ошибка БД", dbManager.lastError)
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }
        }
    }
}
