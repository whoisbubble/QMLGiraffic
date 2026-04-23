import QtQuick
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: workersWin

    width: 1040
    height: 760
    minimumWidth: 980
    minimumHeight: 720
    title: "Сотрудники"
    flags: Qt.Window | Qt.FramelessWindowHint
    color: "transparent"
    modality: Qt.ApplicationModal

    AppTheme { id: theme }
    NotifyWindow { id: notifyDialog }

    property var owner: null
    property var workersList: dbManager.getWorkersList()

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
                onPressed: workersWin.startSystemMove()
            }

            Text {
                text: "Сотрудники"
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
                color: closeWArea.containsMouse ? "#ff8080" : theme.danger
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                    id: closeWArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: workersWin.close()
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
                Layout.preferredWidth: parent.width * 0.36
                title: "База сотрудников"
                subtitle: "Активный персонал"
                accent: theme.sky

                ListView {
                    id: list
                    anchors.fill: parent
                    clip: true
                    spacing: 8
                    model: workersWin.workersList

                    delegate: Rectangle {
                        width: list.width
                        height: 48
                        radius: 8
                        color: "#1d241f"
                        border.color: theme.line

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Rectangle {
                                Layout.preferredWidth: 28
                                Layout.preferredHeight: 28
                                radius: 8
                                color: Qt.rgba(84 / 255, 209 / 255, 122 / 255, 0.16)
                                border.color: theme.leaf

                                Text {
                                    anchors.centerIn: parent
                                    text: "P"
                                    color: theme.leaf
                                    font.bold: true
                                    font.pixelSize: 13
                                }
                            }

                            Text {
                                text: modelData.text
                                color: theme.text
                                font.pixelSize: 14
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                spacing: 16

                AppPanel {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 290
                    title: "Новый сотрудник"
                    subtitle: "ФИО, телефон и email"
                    accent: theme.leaf

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 12

                        AppField {
                            id: fName
                            placeholderText: "ФИО"
                            Layout.fillWidth: true
                        }

                        AppField {
                            id: phone
                            placeholderText: "Телефон"
                            Layout.fillWidth: true
                        }

                        AppField {
                            id: email
                            placeholderText: "Email"
                            Layout.fillWidth: true
                        }

                        AppButton {
                            text: "Зарегистрировать"
                            variant: "green"
                            Layout.fillWidth: true
                            onClicked: {
                                if (fName.text === "") return
                                if (dbManager.addWorker(fName.text, phone.text, email.text, true)) {
                                    notifyDialog.showMsg("Успех", "Сотрудник добавлен.")
                                    fName.text = ""
                                    phone.text = ""
                                    email.text = ""
                                    workersWin.workersList = dbManager.getWorkersList()
                                    if (workersWin.owner && workersWin.owner.refreshAll) {
                                        workersWin.owner.refreshAll()
                                    }
                                } else {
                                    notifyDialog.showMsg("Ошибка БД", dbManager.lastError)
                                }
                            }
                        }
                    }
                }

                AppPanel {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 330
                    title: "Недоступность"
                    subtitle: "Отпуск, болезнь или занятость"
                    accent: theme.danger

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 12

                        AppComboBox {
                            id: unavailCombo
                            Layout.fillWidth: true
                            model: workersWin.workersList
                            textRole: "text"
                            valueRole: "value"
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            AppField {
                                id: uStart
                                placeholderText: "С: ДД.ММ.ГГГГ ЧЧ:ММ"
                                Layout.fillWidth: true
                            }

                            AppField {
                                id: uEnd
                                placeholderText: "По: ДД.ММ.ГГГГ ЧЧ:ММ"
                                Layout.fillWidth: true
                            }
                        }

                        AppField {
                            id: uReason
                            placeholderText: "Причина"
                            Layout.fillWidth: true
                        }

                        AppButton {
                            text: "Добавить недоступность"
                            variant: "danger"
                            Layout.fillWidth: true
                            onClicked: {
                                let sd = workersWin.parseRuDate(uStart.text)
                                let ed = workersWin.parseRuDate(uEnd.text)
                                if (!sd || !ed) {
                                    notifyDialog.showMsg("Ошибка", "Неверный формат даты.")
                                    return
                                }

                                if (dbManager.addWorkerUnavailability(unavailCombo.currentValue, sd, ed, uReason.text)) {
                                    notifyDialog.showMsg("Успех", "Недоступность добавлена.")
                                    uStart.text = ""
                                    uEnd.text = ""
                                    uReason.text = ""
                                } else {
                                    notifyDialog.showMsg("Ошибка БД", dbManager.lastError)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
