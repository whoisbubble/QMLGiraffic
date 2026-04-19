import QtQuick
import QtQuick.Controls

TextField {
    id: field

    implicitHeight: 42
    color: "#f4f7ef"
    placeholderTextColor: "#8d9a8f"
    selectedTextColor: "#111513"
    selectionColor: "#f5c84b"
    font.pixelSize: 14
    leftPadding: 14
    rightPadding: 14
    verticalAlignment: TextInput.AlignVCenter

    background: Rectangle {
        radius: 8
        color: field.activeFocus ? "#2a332d" : "#202722"
        border.color: field.activeFocus ? "#f5c84b" : "#3c4a40"
        border.width: 1
    }
}
