import QtQuick

Item {
    id: pattern

    property real strength: 0.18
    property color spotColor: "#6b5234"

    Repeater {
        model: [
            { "x": 0.06, "y": 0.12, "s": 38 },
            { "x": 0.19, "y": 0.82, "s": 28 },
            { "x": 0.33, "y": 0.22, "s": 18 },
            { "x": 0.58, "y": 0.10, "s": 44 },
            { "x": 0.73, "y": 0.78, "s": 24 },
            { "x": 0.88, "y": 0.34, "s": 34 },
            { "x": 0.96, "y": 0.88, "s": 52 }
        ]

        Rectangle {
            width: modelData.s
            height: modelData.s * 0.72
            radius: Math.min(width, height) / 2
            x: pattern.width * modelData.x - width / 2
            y: pattern.height * modelData.y - height / 2
            rotation: (index % 2 === 0 ? -16 : 18)
            color: pattern.spotColor
            opacity: pattern.strength
        }
    }
}
