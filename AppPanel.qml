import QtQuick
import QtQuick.Layouts

Rectangle {
    id: panel

    property string title: ""
    property string subtitle: ""
    property color accent: "#f5c84b"
    default property alias content: body.data

    radius: 8
    color: "#202722"
    border.color: "#3c4a40"
    border.width: 1
    clip: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            visible: panel.title.length > 0 || panel.subtitle.length > 0
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 5
                Layout.preferredHeight: 34
                radius: 3
                color: panel.accent
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: panel.title
                    visible: text.length > 0
                    color: "#f4f7ef"
                    font.bold: true
                    font.pixelSize: 17
                }

                Text {
                    text: panel.subtitle
                    visible: text.length > 0
                    color: "#9aa79a"
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }

        Item {
            id: body
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
