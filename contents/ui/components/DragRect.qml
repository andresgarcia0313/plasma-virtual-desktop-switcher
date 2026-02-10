import QtQuick 2.15
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents

Rectangle {
    id: root

    property string dragName: ""
    property bool active: false

    visible: active
    color: PlasmaCore.Theme.highlightColor
    opacity: 0.9
    radius: 4
    z: 1000

    PlasmaComponents.Label {
        anchors.centerIn: parent
        text: root.dragName
        font.bold: true
        color: PlasmaCore.Theme.highlightedTextColor
    }
}
