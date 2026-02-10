import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import "DesktopManager.js" as DM
import "components" as Components
import "dialogs" as Dialogs
import "." as Local

Item {
    id: root

    property var pagerModel
    property bool showPreviews: true
    property bool showIcons: true
    property int previewSize: 130

    signal hoverEntered()
    signal hoverExited()
    signal desktopClicked(int index)
    signal deleteDesktop(int index)
    signal createDesktop(string name)
    signal renameDesktop(int index, string name)
    signal swapDesktops(int indexA, int indexB)
    signal sizeCommitted(int size)
    signal closeRequested()

    property bool dialogOpen: newDlg.visible || renameDlg.visible

    // Use JS for calculations
    readonly property var gridSize: DM.calculateGrid(pagerModel ? pagerModel.count : 1)
    readonly property var previewDims: DM.calculatePreviewSize(
        previewSize,
        pagerModel ? pagerModel.pagerItemSize.width : 1920,
        pagerModel ? pagerModel.pagerItemSize.height : 1080
    )
    readonly property var scaleFactor: DM.calculateScale(
        previewDims.width, previewDims.height,
        pagerModel ? pagerModel.pagerItemSize.width : 1920,
        pagerModel ? pagerModel.pagerItemSize.height : 1080
    )

    Layout.preferredWidth: gridSize.cols * (previewDims.width + 8) + 32
    Layout.preferredHeight: gridSize.rows * (previewDims.height + 8) + 70
    Layout.minimumWidth: 200
    Layout.minimumHeight: 120

    // Drag state
    property int dragSource: -1
    property int dropTarget: -1

    // Background mouse area
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        z: -1
        onEntered: root.hoverEntered()
        onExited: root.hoverExited()
        onReleased: {
            dragSource = -1
            dropTarget = -1
            dragRect.active = false
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        // Desktop grid
        Grid {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignHCenter
            columns: gridSize.cols
            spacing: 6

            Repeater {
                id: repeater
                model: pagerModel

                DesktopDelegate {
                    width: previewDims.width
                    height: previewDims.height
                    desktopIndex: index
                    desktopName: model.display || (Local.Translations.t.desktop + " " + (index + 1))
                    isActive: pagerModel ? index === pagerModel.currentPage : false
                    showPreviews: root.showPreviews
                    showIcons: root.showIcons
                    scaleX: scaleFactor.x
                    scaleY: scaleFactor.y
                    isDragTarget: root.dropTarget === index && root.dragSource !== index
                    isDragSource: root.dragSource === index
                    canDelete: pagerModel ? pagerModel.count > 1 : false

                    onClicked: {
                        root.desktopClicked(index)
                        root.closeRequested()
                    }
                    onRightClicked: ctxMenu.show(index, desktopName)
                    onDeleteRequested: root.deleteDesktop(index)

                    onDragStarted: function(idx, name) {
                        root.dragSource = idx
                        dragRect.dragName = name
                        dragRect.active = true
                    }
                    onDragMoved: function(mx, my) {
                        var pos = mapToItem(root, mx, my)
                        dragRect.x = pos.x - dragRect.width / 2
                        dragRect.y = pos.y - dragRect.height / 2

                        // Find drop target
                        var gpos = mapToItem(grid, mx, my)
                        root.dropTarget = -1
                        for (var i = 0; i < repeater.count; i++) {
                            var item = repeater.itemAt(i)
                            if (!item) continue
                            var ipos = grid.mapFromItem(item, 0, 0)
                            if (gpos.x >= ipos.x && gpos.x < ipos.x + item.width &&
                                gpos.y >= ipos.y && gpos.y < ipos.y + item.height) {
                                root.dropTarget = i
                                break
                            }
                        }
                    }
                    onDragEnded: {
                        if (root.dragSource >= 0 && root.dropTarget >= 0 && root.dragSource !== root.dropTarget) {
                            root.swapDesktops(root.dragSource, root.dropTarget)
                        }
                        root.dragSource = -1
                        root.dropTarget = -1
                        dragRect.active = false
                    }
                }
            }
        }

        // Bottom bar
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            spacing: 8

            PlasmaComponents.Button {
                icon.name: "list-add"
                text: Local.Translations.t.add
                onClicked: newDlg.open(Local.Translations.t.desktop + " " + (pagerModel ? pagerModel.count + 1 : 1))
            }

            Item { Layout.fillWidth: true }

            PlasmaComponents.Label {
                text: (pagerModel ? pagerModel.count : 0) + " " + Local.Translations.t.desktops
                opacity: 0.6
                font.pixelSize: 11
            }

            // Resize handle
            Rectangle {
                width: 24
                height: 24
                color: "transparent"

                PlasmaCore.IconItem {
                    anchors.fill: parent
                    anchors.margins: 2
                    source: "transform-scale"
                    opacity: resizeArea.containsMouse || resizeArea.pressed ? 1 : 0.4
                }

                MouseArea {
                    id: resizeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.SizeFDiagCursor
                    property int startY: 0
                    property int startSize: 0

                    onPressed: {
                        startY = mouseY
                        startSize = root.previewSize
                    }
                    onPositionChanged: {
                        if (pressed) {
                            root.previewSize = Math.max(80, Math.min(200, Math.round(startSize + (mouseY - startY) * 0.8)))
                        }
                    }
                    onReleased: root.sizeCommitted(root.previewSize)
                }
            }
        }
    }

    // Drag rectangle
    Components.DragRect {
        id: dragRect
        width: previewDims.width - 4
        height: previewDims.height - 4
    }

    // Dialogs
    Dialogs.NewDesktopDialog {
        id: newDlg
        onAccepted: function(name) { root.createDesktop(name) }
    }

    Dialogs.RenameDialog {
        id: renameDlg
        onAccepted: function(idx, name) { root.renameDesktop(idx, name) }
    }

    // Context menu
    Menu {
        id: ctxMenu
        property int idx: 0
        property string name: ""

        function show(i, n) {
            idx = i
            name = n
            popup()
        }

        MenuItem {
            text: Local.Translations.t.switchTo + " \"" + ctxMenu.name + "\""
            icon.name: "go-jump"
            onTriggered: {
                root.desktopClicked(ctxMenu.idx)
                root.closeRequested()
            }
        }
        MenuSeparator {}
        MenuItem {
            text: Local.Translations.t.rename
            icon.name: "edit-rename"
            onTriggered: renameDlg.open(ctxMenu.idx, ctxMenu.name)
        }
        MenuItem {
            text: Local.Translations.t.delete_
            icon.name: "edit-delete"
            enabled: pagerModel ? pagerModel.count > 1 : false
            onTriggered: root.deleteDesktop(ctxMenu.idx)
        }
        MenuSeparator {}
        MenuItem {
            text: Local.Translations.t.newDesktop
            icon.name: "list-add"
            onTriggered: newDlg.open(Local.Translations.t.desktop + " " + (pagerModel ? pagerModel.count + 1 : 1))
        }
    }
}
