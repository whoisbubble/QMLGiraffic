import QtQuick
import QtQuick.Controls

ComboBox {
    id: combo

    implicitHeight: 42
    font.pixelSize: 14

    background: Rectangle {
        radius: 8
        color: combo.activeFocus ? "#2a332d" : "#202722"
        border.color: combo.activeFocus ? "#f5c84b" : "#3c4a40"
        border.width: 1
    }

    contentItem: Text {
        text: combo.displayText
        color: "#f4f7ef"
        leftPadding: 14
        rightPadding: 30
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        font.pixelSize: 14
    }

    indicator: Text {
        text: "⌄"
        color: "#f5c84b"
        font.pixelSize: 18
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
    }

    popup: Popup {
        y: combo.height + 6
        width: combo.width
        implicitHeight: Math.min(contentItem.implicitHeight + 8, 260)
        padding: 4

        background: Rectangle {
            radius: 8
            color: "#202722"
            border.color: "#3c4a40"
        }

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: combo.popup.visible ? combo.delegateModel : null
            currentIndex: combo.highlightedIndex
        }
    }
}
