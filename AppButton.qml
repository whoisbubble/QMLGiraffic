import QtQuick

Rectangle {
    id: control

    property string text: ""
    property string variant: "primary"
    property bool busy: false
    signal clicked()

    implicitHeight: 42
    radius: 8
    opacity: enabled ? 1.0 : 0.45
    color: {
        if (!enabled) return "#556058"
        if (variant === "danger") return area.pressed ? "#b63f3f" : (area.containsMouse ? "#f06a6a" : "#e75b5b")
        if (variant === "ghost") return area.pressed ? "#2a332d" : (area.containsMouse ? "#344038" : "#243028")
        if (variant === "blue") return area.pressed ? "#2d83a0" : (area.containsMouse ? "#55c5e8" : "#4eb7d8")
        if (variant === "green") return area.pressed ? "#39a85a" : (area.containsMouse ? "#65e389" : "#54d17a")
        return area.pressed ? "#d7aa31" : (area.containsMouse ? "#ffe28a" : "#f5c84b")
    }

    border.color: variant === "ghost" ? "#4d5b50" : Qt.rgba(1, 1, 1, 0.12)
    border.width: 1

    Text {
        anchors.centerIn: parent
        text: control.busy ? "..." : control.text
        color: control.variant === "ghost" || control.variant === "danger" || control.variant === "blue" ? "#f4f7ef" : "#111513"
        font.bold: true
        font.pixelSize: 13
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    MouseArea {
        id: area
        anchors.fill: parent
        enabled: control.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: control.clicked()
    }

    Behavior on color { ColorAnimation { duration: 140 } }
    Behavior on opacity { NumberAnimation { duration: 140 } }
}
