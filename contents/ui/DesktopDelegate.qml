import QtQuick 2.15
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.private.pager 2.0
import "." as Local

Item {
    id: root

    property int desktopIndex: 0
    property string desktopName: ""
    property bool isActive: false
    property bool showPreviews: true
    property bool showIcons: true
    property real scaleX: 1
    property real scaleY: 1
    property bool isDragTarget: false
    property bool isDragSource: false
    property bool canDelete: true

    signal clicked()
    signal rightClicked()
    signal deleteRequested()
    signal dragStarted(int index, string name)
    signal dragMoved(real mouseX, real mouseY)
    signal dragEnded()

    property bool isHovered: mouseArea.containsMouse || deleteBtn.containsMouse

    Rectangle {
        id: desktop
        anchors.fill: parent
        anchors.margins: root.isDragTarget ? 0 : 2
        color: root.isActive ? Qt.darker(PlasmaCore.Theme.highlightColor, 1.3) : PlasmaCore.Theme.backgroundColor
        border.width: root.isDragTarget ? 3 : (root.isActive ? 2 : 1)
        border.color: root.isDragTarget ? "#3498db" : (root.isActive ? PlasmaCore.Theme.highlightColor : PlasmaCore.Theme.disabledTextColor)
        radius: 4; clip: true
        opacity: root.isDragSource ? 0.5 : (root.isHovered ? 1 : 0.92)
        Behavior on opacity { NumberAnimation { duration: 100 } }
        Behavior on anchors.margins { NumberAnimation { duration: 100 } }

        // Windows
        Item {
            anchors.fill: parent; anchors.margins: 2; clip: true
            visible: root.showPreviews
            Repeater {
                model: TasksModel
                Rectangle {
                    readonly property rect geo: model.Geometry
                    x: Math.round(geo.x * root.scaleX); y: Math.round(geo.y * root.scaleY)
                    width: Math.max(8, Math.round(geo.width * root.scaleX))
                    height: Math.max(6, Math.round(geo.height * root.scaleY))
                    visible: model.IsMinimized !== true
                    color: model.IsActive ? Qt.rgba(1,1,1,0.4) : Qt.rgba(1,1,1,0.2)
                    border.width: 1; border.color: model.IsActive ? PlasmaCore.Theme.highlightColor : PlasmaCore.Theme.textColor; radius: 2
                    PlasmaCore.IconItem {
                        visible: root.showIcons && parent.width > 16 && parent.height > 12
                        anchors.centerIn: parent
                        width: Math.min(parent.width - 4, parent.height - 4, 20); height: width
                        source: model.decoration || "application-x-executable"; usesPlasmaTheme: false
                    }
                }
            }
        }

        // Label (when no previews)
        Column {
            anchors.centerIn: parent; visible: !root.showPreviews
            PlasmaComponents.Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.desktopIndex + 1; font.bold: true; font.pixelSize: 18
                color: root.isActive ? PlasmaCore.Theme.highlightedTextColor : PlasmaCore.Theme.textColor
            }
            PlasmaComponents.Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.desktopName; font.pixelSize: 10; width: root.width - 14
                elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                color: root.isActive ? PlasmaCore.Theme.highlightedTextColor : PlasmaCore.Theme.textColor
            }
        }

        // Badge (when previews enabled)
        Rectangle {
            visible: root.showPreviews
            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 3 }
            width: badgeLbl.implicitWidth + 12; height: badgeLbl.implicitHeight + 4
            color: Qt.rgba(0,0,0,0.7); radius: 3
            PlasmaComponents.Label {
                id: badgeLbl; anchors.centerIn: parent
                text: (root.desktopIndex + 1) + " " + root.desktopName
                font.pixelSize: 11; font.bold: true; color: "white"
            }
        }
    }

    // Delete button
    Rectangle {
        id: deleteBtn
        visible: root.isHovered && root.canDelete && !root.isDragSource
        anchors { top: parent.top; right: parent.right; margins: 4 }
        width: Math.min(parent.width * 0.25, 36); height: width; radius: width / 2
        color: deleteArea.containsMouse ? "#e74c3c" : Qt.rgba(0,0,0,0.7)
        property bool containsMouse: deleteArea.containsMouse
        Behavior on color { ColorAnimation { duration: 100 } }
        PlasmaCore.IconItem { anchors.centerIn: parent; width: parent.width * 0.6; height: width; source: "edit-delete" }
        MouseArea { id: deleteArea; anchors.fill: parent; hoverEnabled: true; onClicked: root.deleteRequested() }
    }

    // Main mouse area
    MouseArea {
        id: mouseArea
        anchors.fill: parent; hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        property real startX: 0; property real startY: 0; property bool dragging: false

        onPressed: function(mouse) { if (mouse.button === Qt.LeftButton) { startX = mouse.x; startY = mouse.y; dragging = false } }
        onPositionChanged: function(mouse) {
            if (!(mouse.buttons & Qt.LeftButton)) return
            var dist = Math.sqrt(Math.pow(mouse.x - startX, 2) + Math.pow(mouse.y - startY, 2))
            if (!dragging && dist > 10) { dragging = true; root.dragStarted(root.desktopIndex, root.desktopName) }
            if (dragging) root.dragMoved(mouse.x, mouse.y)
        }
        onReleased: function(mouse) { if (mouse.button === Qt.LeftButton && dragging) root.dragEnded(); dragging = false }
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) root.rightClicked()
            else if (!dragging) root.clicked()
        }
    }
}
