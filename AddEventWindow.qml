import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: addEventWin

    width: 560
    height: 660
    title: "Создание мероприятия"
    flags: Qt.Window | Qt.FramelessWindowHint
    color: "transparent"
    modality: Qt.ApplicationModal

    AppTheme { id: theme }
    NotifyWindow { id: notifyDialog }

    property var owner: null
    property var clientsData: dbManager.getClientsList()
    property var venuesData: dbManager.getVenuesList()

    function parseRuDate(str) {
        var parts = str.split(" ")
        if (parts.length !== 2) return null
        var d = parts[0].split(".")
        var t = parts[1].split(":")
        if (d.length !== 3 || t.length !== 2) return null
        return new Date(d[2], d[1] - 1, d[0], t[0], t[1])
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 10
        radius: 8
        color: theme.ink
        border.color: theme.line
        clip: true

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#253127" }
            GradientStop { position: 1.0; color: theme.shell }
        }

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
                onPressed: addEventWin.startSystemMove()
            }

            Text {
                text: "Новое мероприятие"
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
                    onClicked: addEventWin.close()
                }
            }
        }

        AppPanel {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: titleBar.bottom
            anchors.bottom: parent.bottom
            anchors.margins: 18
            title: "Карточка события"
            subtitle: "Клиент, площадка, время и заметки"
            accent: theme.leaf

            ColumnLayout {
                anchors.fill: parent
                spacing: 12

                AppField {
                    id: titleField
                    placeholderText: "Название мероприятия"
                    Layout.fillWidth: true
                }

                Text {
                    text: "Клиент"
                    color: theme.muted
                    font.pixelSize: 12
                    font.bold: true
                }

                AppComboBox {
                    id: clientCombo
                    Layout.fillWidth: true
                    model: addEventWin.clientsData
                    textRole: "text"
                    valueRole: "value"
                }

                Text {
                    text: "Площадка"
                    color: theme.muted
                    font.pixelSize: 12
                    font.bold: true
                }

                AppComboBox {
                    id: venueCombo
                    Layout.fillWidth: true
                    model: addEventWin.venuesData
                    textRole: "text"
                    valueRole: "value"
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    AppField {
                        id: startField
                        placeholderText: "Начало: ДД.ММ.ГГГГ ЧЧ:ММ"
                        text: "25.10.2026 18:00"
                        Layout.fillWidth: true
                    }

                    AppField {
                        id: endField
                        placeholderText: "Конец: ДД.ММ.ГГГГ ЧЧ:ММ"
                        text: "25.10.2026 23:00"
                        Layout.fillWidth: true
                    }
                }

                TextArea {
                    id: notesField
                    placeholderText: "Стоимость для клиента и дополнительная информация..."
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: theme.text
                    placeholderTextColor: theme.muted
                    selectedTextColor: theme.ink
                    selectionColor: theme.amber
                    font.pixelSize: 14
                    wrapMode: TextArea.Wrap
                    leftPadding: 14
                    rightPadding: 14
                    topPadding: 12
                    bottomPadding: 12

                    background: Rectangle {
                        radius: 8
                        color: notesField.activeFocus ? theme.surfaceHigh : theme.surface
                        border.color: notesField.activeFocus ? theme.amber : theme.line
                    }
                }

                AppButton {
                    text: "Создать и сохранить"
                    variant: "green"
                    Layout.fillWidth: true
                    onClicked: {
                        let startDt = addEventWin.parseRuDate(startField.text)
                        let endDt = addEventWin.parseRuDate(endField.text)
                        if (!startDt || !endDt) {
                            notifyDialog.showMsg("Ошибка ввода", "Неверный формат даты. Используйте: ДД.ММ.ГГГГ ЧЧ:ММ")
                            return
                        }

                        if (dbManager.addEvent(titleField.text, clientCombo.currentValue, venueCombo.currentValue, startDt, endDt, notesField.text)) {
                            if (addEventWin.owner && addEventWin.owner.refreshAll) {
                                addEventWin.owner.refreshAll()
                            }
                            addEventWin.close()
                        } else {
                            notifyDialog.showMsg("Ошибка БД", dbManager.lastError)
                        }
                    }
                }
            }
        }
    }
}
