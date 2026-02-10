import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import "." as Local

MouseArea {
    id: root

    property var pagerModel
    property string currentName: ""

    signal requestOpen()
    signal requestClose()
    signal requestToggle()
    signal wheelUp()
    signal wheelDown()

    Layout.minimumWidth: label.implicitWidth + 16
    hoverEnabled: true

    Rectangle {
        anchors.fill: parent
        color: parent.containsMouse ? PlasmaCore.Theme.highlightColor : "transparent"
        opacity: 0.2
        radius: 3
    }

    PlasmaComponents.Label {
        id: label
        anchors.centerIn: parent
        text: currentName || Local.Translations.t.desktop
        font.bold: true
    }

    onEntered: requestOpen()
    onExited: requestClose()
    onClicked: requestToggle()

    onWheel: function(wheel) {
        if (wheel.angleDelta.y > 0) wheelUp()
        else wheelDown()
    }
}
