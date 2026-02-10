import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.private.pager 2.0
import "DesktopLogic.js" as Logic

Item {
    id: root
    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation

    readonly property bool showPreviews: plasmoid.configuration.showWindowPreviews
    readonly property bool showIcons: plasmoid.configuration.showWindowIcons
    property int previewSize: plasmoid.configuration.previewSize || 130

    property bool hoverCompact: false
    property bool hoverPopup: false

    Timer { id: openTimer; interval: 80; onTriggered: plasmoid.expanded = true }
    Timer { id: closeTimer; interval: 400; onTriggered: if (!hoverCompact && !hoverPopup) plasmoid.expanded = false }

    PagerModel {
        id: pagerModel
        enabled: true
        showDesktop: false
        pagerType: PagerModel.VirtualDesktops
    }

    // Store desktop IDs fetched from D-Bus
    property var desktopIds: ({})

    PlasmaCore.DataSource {
        id: executable
        engine: "executable"
        onNewData: {
            var stdout = data["stdout"] || ""
            // Parse desktop IDs from qdbus output
            if (sourceName.indexOf("desktops") > -1) {
                parseDesktopIds(stdout)
            }
            disconnectSource(sourceName)
        }

        Component.onCompleted: refreshDesktopIds()
    }

    function refreshDesktopIds() {
        executable.connectSource("qdbus --literal org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager.desktops")
    }

    function parseDesktopIds(output) {
        // Parse: [Argument: (uss) 0, "uuid", "name"], ...
        var regex = /\[Argument: \(uss\) (\d+), "([^"]+)", "([^"]+)"\]/g
        var match
        var ids = {}
        while ((match = regex.exec(output)) !== null) {
            var idx = parseInt(match[1])
            ids[idx] = match[2]
        }
        desktopIds = ids
    }

    // Refresh IDs when desktop count changes
    Connections {
        target: pagerModel
        function onCountChanged() {
            refreshDesktopIds()
        }
    }

    function run(cmd) {
        if (cmd) {
            executable.connectSource(cmd)
        }
    }

    function getDesktopId(index) {
        if (index < 0 || index >= pagerModel.count) return ""
        return desktopIds[index] || ""
    }

    function getDesktopName(index) {
        return pagerModel.data(pagerModel.index(index, 0), Qt.DisplayRole) || ("Desktop " + (index + 1))
    }

    function currentDesktopName() {
        if (pagerModel.count > 0 && pagerModel.currentPage >= 0)
            return getDesktopName(pagerModel.currentPage)
        return "Desktop"
    }

    Plasmoid.compactRepresentation: MouseArea {
        Layout.minimumWidth: compactLabel.implicitWidth + 16
        hoverEnabled: true

        Rectangle {
            anchors.fill: parent
            color: parent.containsMouse ? PlasmaCore.Theme.highlightColor : "transparent"
            opacity: 0.2; radius: 3
        }

        PlasmaComponents.Label {
            id: compactLabel
            anchors.centerIn: parent
            text: currentDesktopName()
            font.bold: true
        }

        onEntered: { hoverCompact = true; closeTimer.stop(); openTimer.start() }
        onExited: { hoverCompact = false; openTimer.stop(); if (!hoverPopup) closeTimer.start() }
        onClicked: { openTimer.stop(); closeTimer.stop(); plasmoid.expanded = !plasmoid.expanded }
        onWheel: function(wheel) {
            pagerModel.changePage(Logic.nextDesktop(pagerModel.currentPage, pagerModel.count, wheel.angleDelta.y > 0 ? -1 : 1))
        }
    }

    Plasmoid.fullRepresentation: Item {
        id: popup

        readonly property var gridDims: Logic.calculateGrid(pagerModel.count)
        readonly property real deskW: previewSize
        readonly property real deskH: Logic.calculatePreviewHeight(previewSize, pagerModel.pagerItemSize.width, pagerModel.pagerItemSize.height)
        readonly property real scaleX: deskW / Math.max(1, pagerModel.pagerItemSize.width)
        readonly property real scaleY: deskH / Math.max(1, pagerModel.pagerItemSize.height)

        Layout.preferredWidth: gridDims.cols * (deskW + 8) + 32
        Layout.preferredHeight: gridDims.rows * (deskH + 8) + 70
        Layout.minimumWidth: 200
        Layout.minimumHeight: 120

        property int dragSource: -1
        property int dropTarget: -1

        Timer {
            id: refreshTimer
            interval: 300
            onTriggered: pagerModel.refresh()
        }

        PlasmaComponents.Menu {
            id: contextMenu
            property int desktopIndex: -1
            property string desktopName: ""
            property string desktopId: ""

            PlasmaComponents.MenuItem {
                text: "Switch to"
                icon.name: "go-jump"
                onClicked: {
                    pagerModel.changePage(contextMenu.desktopIndex)
                    plasmoid.expanded = false
                }
            }
            PlasmaComponents.MenuItem {
                text: "Rename..."
                icon.name: "edit-rename"
                onClicked: {
                    renameDialog.desktopId = contextMenu.desktopId
                    renameDialog.desktopName = contextMenu.desktopName
                    renameDialog.open()
                }
            }
            PlasmaComponents.MenuSeparator {}
            PlasmaComponents.MenuItem {
                text: "Delete"
                icon.name: "edit-delete"
                enabled: pagerModel.count > 1
                onClicked: run(Logic.buildRemoveCommand(contextMenu.desktopId))
            }
            PlasmaComponents.MenuSeparator {}
            PlasmaComponents.MenuItem {
                text: "New Desktop"
                icon.name: "list-add"
                onClicked: run(Logic.buildCreateCommand(pagerModel.count, "Desktop " + (pagerModel.count + 1)))
            }
        }

        Dialog {
            id: renameDialog
            title: "Rename Desktop"
            anchors.centerIn: parent
            modal: true
            standardButtons: Dialog.Ok | Dialog.Cancel

            property string desktopId: ""
            property string desktopName: ""

            onOpened: {
                renameField.text = desktopName
                renameField.selectAll()
                renameField.forceActiveFocus()
            }

            onAccepted: {
                if (renameField.text.trim()) {
                    run(Logic.buildRenameCommand(desktopId, renameField.text.trim()))
                    refreshTimer.start()
                }
            }

            contentItem: ColumnLayout {
                spacing: 10
                PlasmaComponents.Label {
                    text: "Enter new name:"
                }
                PlasmaComponents.TextField {
                    id: renameField
                    Layout.fillWidth: true
                    Layout.preferredWidth: 250
                    onAccepted: renameDialog.accept()
                }
            }
        }

        // Track hover state for entire popup
        HoverHandler {
            id: popupHover
            onHoveredChanged: {
                if (hovered) {
                    hoverPopup = true
                    closeTimer.stop()
                } else {
                    hoverPopup = false
                    if (!hoverCompact) closeTimer.start()
                }
            }
        }

        // Cleanup drag on release anywhere
        TapHandler {
            acceptedButtons: Qt.LeftButton
            onCanceled: { popup.dragSource = -1; popup.dropTarget = -1 }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            Grid {
                id: grid
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignHCenter
                columns: popup.gridDims.cols
                spacing: 6

                Repeater {
                    id: repeater
                    model: pagerModel

                    Rectangle {
                        id: desktopItem
                        width: popup.deskW
                        height: popup.deskH
                        color: index === pagerModel.currentPage
                            ? Qt.darker(PlasmaCore.Theme.highlightColor, 1.3)
                            : PlasmaCore.Theme.backgroundColor
                        border.width: popup.dropTarget === index && popup.dragSource !== index ? 3 : (index === pagerModel.currentPage ? 2 : 1)
                        border.color: popup.dropTarget === index && popup.dragSource !== index
                            ? "#3498db"
                            : (index === pagerModel.currentPage ? PlasmaCore.Theme.highlightColor : PlasmaCore.Theme.disabledTextColor)
                        radius: 4
                        clip: true
                        opacity: popup.dragSource === index ? 0.5 : (desktopMA.containsMouse || deleteMA.containsMouse ? 1 : 0.92)

                        property string desktopName: model.display || ("Desktop " + (index + 1))
                        property bool isHovered: desktopMA.containsMouse || deleteMA.containsMouse

                        // Windows
                        Item {
                            anchors.fill: parent
                            anchors.margins: 2
                            clip: true
                            visible: showPreviews

                            Repeater {
                                model: TasksModel
                                Rectangle {
                                    property rect geo: model.Geometry
                                    x: Math.round(geo.x * popup.scaleX)
                                    y: Math.round(geo.y * popup.scaleY)
                                    width: Math.max(8, Math.round(geo.width * popup.scaleX))
                                    height: Math.max(6, Math.round(geo.height * popup.scaleY))
                                    visible: model.IsMinimized !== true
                                    color: model.IsActive ? Qt.rgba(1,1,1,0.4) : Qt.rgba(1,1,1,0.2)
                                    border.width: 1
                                    border.color: model.IsActive ? PlasmaCore.Theme.highlightColor : PlasmaCore.Theme.textColor
                                    radius: 2

                                    PlasmaCore.IconItem {
                                        visible: showIcons && parent.width > 16 && parent.height > 12
                                        anchors.centerIn: parent
                                        width: Math.min(parent.width - 4, parent.height - 4, 20)
                                        height: width
                                        source: model.decoration || "application-x-executable"
                                        usesPlasmaTheme: false
                                    }
                                }
                            }
                        }

                        // Badge
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottomMargin: 3
                            width: badgeLabel.implicitWidth + 12
                            height: badgeLabel.implicitHeight + 4
                            color: Qt.rgba(0,0,0,0.7)
                            radius: 3

                            PlasmaComponents.Label {
                                id: badgeLabel
                                anchors.centerIn: parent
                                text: (index + 1) + " " + desktopItem.desktopName
                                font.pixelSize: 11
                                font.bold: true
                                color: "white"
                            }
                        }

                        MouseArea {
                            id: desktopMA
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton

                            property real startX: 0
                            property real startY: 0
                            property bool dragging: false

                            onPressed: function(mouse) {
                                if (mouse.button === Qt.LeftButton) {
                                    startX = mouse.x
                                    startY = mouse.y
                                    dragging = false
                                }
                            }

                            onPositionChanged: function(mouse) {
                                if (!(mouse.buttons & Qt.LeftButton)) return
                                var dist = Math.sqrt(Math.pow(mouse.x - startX, 2) + Math.pow(mouse.y - startY, 2))
                                if (!dragging && dist > 10) {
                                    dragging = true
                                    popup.dragSource = index
                                    dragRect.dragName = desktopItem.desktopName
                                }
                                if (dragging) {
                                    var pos = mapToItem(popup, mouse.x, mouse.y)
                                    dragRect.x = pos.x - dragRect.width / 2
                                    dragRect.y = pos.y - dragRect.height / 2

                                    var gpos = mapToItem(grid, mouse.x, mouse.y)
                                    popup.dropTarget = Logic.findDropTarget(repeater, grid, gpos.x, gpos.y)
                                }
                            }

                            onReleased: function(mouse) {
                                if (mouse.button === Qt.LeftButton && dragging && Logic.canSwap(popup.dragSource, popup.dropTarget, pagerModel.count)) {
                                    var idxA = popup.dragSource
                                    var idxB = popup.dropTarget
                                    var nameA = getDesktopName(idxA)
                                    var nameB = getDesktopName(idxB)
                                    var idA = getDesktopId(idxA)
                                    var idB = getDesktopId(idxB)

                                    if (idA && idB) {
                                        run(Logic.buildSwapWindowsCommand(idxA, idxB))
                                        run(Logic.buildRenameCommand(idA, nameB))
                                        run(Logic.buildRenameCommand(idB, nameA))
                                        refreshTimer.start()
                                    }
                                }
                                dragging = false
                                popup.dragSource = -1
                                popup.dropTarget = -1
                            }

                            onClicked: function(mouse) {
                                if (mouse.button === Qt.RightButton) {
                                    contextMenu.desktopIndex = index
                                    contextMenu.desktopName = desktopItem.desktopName
                                    contextMenu.desktopId = getDesktopId(index)
                                    contextMenu.popup()
                                } else if (!dragging) {
                                    pagerModel.changePage(index)
                                    plasmoid.expanded = false
                                }
                            }
                        }

                        // Delete button - declared AFTER desktopMA to receive events first
                        Rectangle {
                            id: deleteBtn
                            visible: desktopItem.isHovered && pagerModel.count > 1 && popup.dragSource < 0
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 4
                            width: Math.min(parent.width * 0.25, 36)
                            height: width
                            radius: width / 2
                            color: deleteMA.containsMouse ? "#e74c3c" : Qt.rgba(0,0,0,0.7)

                            PlasmaCore.IconItem {
                                anchors.centerIn: parent
                                width: parent.width * 0.6
                                height: width
                                source: "edit-delete"
                            }

                            MouseArea {
                                id: deleteMA
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    var id = getDesktopId(index)
                                    if (id) run(Logic.buildRemoveCommand(id))
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                spacing: 8

                PlasmaComponents.Button {
                    icon.name: "list-add"
                    text: "Add"
                    onClicked: run(Logic.buildCreateCommand(pagerModel.count, "Desktop " + (pagerModel.count + 1)))
                }

                Item { Layout.fillWidth: true }

                PlasmaComponents.Label {
                    text: pagerModel.count + " desktops"
                    opacity: 0.6
                    font.pixelSize: 11
                }
            }
        }

        // Drag rectangle
        Rectangle {
            id: dragRect
            visible: popup.dragSource >= 0
            width: popup.deskW - 4
            height: popup.deskH - 4
            color: PlasmaCore.Theme.highlightColor
            opacity: 0.9
            radius: 4
            z: 1000

            property string dragName: ""

            PlasmaComponents.Label {
                anchors.centerIn: parent
                text: dragRect.dragName
                font.bold: true
                color: PlasmaCore.Theme.highlightedTextColor
            }
        }
    }
}
