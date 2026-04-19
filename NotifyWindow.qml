import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: notifyWin

    width: 520
    height: 420
    flags: Qt.Window | Qt.FramelessWindowHint
    modality: Qt.ApplicationModal
    color: "transparent"

    AppTheme { id: theme }

    property string msgTitle: ""
    property string msgText: ""

    function showMsg(t, m) {
        msgTitle = t
        msgText = m
        notifyWin.show()
    }

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: theme.ink
        border.color: theme.amber
        border.width: 1
        clip: true

        GiraffePattern {
            anchors.fill: parent
            strength: 0.10
        }

        MouseArea {
            anchors.fill: parent
            onPressed: notifyWin.startSystemMove()
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 14

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 44
                Layout.preferredHeight: 44
                radius: 8
                color: Qt.rgba(245 / 255, 200 / 255, 75 / 255, 0.14)
                border.color: theme.amber

                Text {
                    anchors.centerIn: parent
                    text: "!"
                    color: theme.amber
                    font.bold: true
                    font.pixelSize: 24
                }
            }

            Text {
                text: notifyWin.msgTitle
                color: theme.text
                font.bold: true
                font.pixelSize: 19
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            ScrollView {
                id: messageScroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                ScrollBar.vertical: ScrollBar {
                    id: verticalScrollBar
                    parent: messageScroll
                    x: messageScroll.width - width
                    y: messageScroll.topPadding
                    height: messageScroll.availableHeight

                    contentItem: Rectangle {
                        implicitWidth: 6
                        implicitHeight: 30
                        radius: 3
                        color: verticalScrollBar.pressed ? theme.amberSoft : theme.amber
                        opacity: verticalScrollBar.size >= 1.0 ? 0.0 : 1.0
                    }

                    background: Rectangle {
                        implicitWidth: 6
                        radius: 3
                        color: theme.line
                        opacity: verticalScrollBar.size >= 1.0 ? 0.0 : 1.0
                    }
                }

                Text {
                    width: messageScroll.availableWidth
                    text: notifyWin.msgText
                    color: theme.text
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            AppButton {
                text: "ОК"
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 132
                onClicked: notifyWin.close()
            }
        }
    }
}
