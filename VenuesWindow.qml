import QtQuick
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: venuesWin

    width: 840
    height: 540
    title: "Площадки"
    flags: Qt.Window | Qt.FramelessWindowHint
    color: "transparent"
    modality: Qt.ApplicationModal

    AppTheme { id: theme }
    NotifyWindow { id: notifyDialog }

    property var venuesList: dbManager.getVenuesList()

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
                onPressed: venuesWin.startSystemMove()
            }

            Text {
                text: "Площадки"
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
                color: closeVArea.containsMouse ? "#ff8080" : theme.danger
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                    id: closeVArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: venuesWin.close()
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
                title: "База площадок"
                subtitle: "Места проведения мероприятий"
                accent: theme.sky

                ListView {
                    id: list
                    anchors.fill: parent
                    clip: true
                    spacing: 8
                    model: venuesWin.venuesList

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
                title: "Новая площадка"
                subtitle: "Название и адрес"
                accent: theme.leaf

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 12

                    AppField {
                        id: vName
                        placeholderText: "Название площадки"
                        Layout.fillWidth: true
                    }

                    AppField {
                        id: vAddress
                        placeholderText: "Адрес"
                        Layout.fillWidth: true
                    }

                    AppButton {
                        text: "Сохранить площадку"
                        variant: "green"
                        Layout.fillWidth: true
                        onClicked: {
                            if (vName.text === "") return
                            if (dbManager.addVenue(vName.text, vAddress.text)) {
                                notifyDialog.showMsg("Успех", "Площадка добавлена.")
                                vName.text = ""
                                vAddress.text = ""
                                venuesWin.venuesList = dbManager.getVenuesList()
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
