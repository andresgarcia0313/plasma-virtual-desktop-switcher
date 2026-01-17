import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.private.pager 2.0

Item {
    id: root
    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation

    // ─────────────────────────────────────────────────────────────────────────
    // CONFIGURATION
    // ─────────────────────────────────────────────────────────────────────────
    readonly property bool showPreviews: plasmoid.configuration.showWindowPreviews
    readonly property bool showIcons: plasmoid.configuration.showWindowIcons

    // ─────────────────────────────────────────────────────────────────────────
    // PAGER MODEL (native KDE plugin with real window geometry)
    // ─────────────────────────────────────────────────────────────────────────
    PagerModel {
        id: pagerModel
        enabled: root.visible
        showDesktop: false
        pagerType: PagerModel.VirtualDesktops
    }

    // ─────────────────────────────────────────────────────────────────────────
    // HELPER FUNCTIONS
    // ─────────────────────────────────────────────────────────────────────────
    function currentDesktopName() {
        if (pagerModel.count > 0 && pagerModel.currentPage >= 0) {
            var idx = pagerModel.index(pagerModel.currentPage, 0)
            var name = pagerModel.data(idx, Qt.DisplayRole)
            return name || ("Desktop " + (pagerModel.currentPage + 1))
        }
        return "Desktop"
    }

    function addDesktop() { pagerModel.addDesktop() }
    function removeDesktop() { pagerModel.removeDesktop() }

    // ─────────────────────────────────────────────────────────────────────────
    // HOVER TIMERS
    // ─────────────────────────────────────────────────────────────────────────
    property bool hoverCompact: false
    property bool hoverPopup: false
    Timer { id: openTimer; interval: 80; onTriggered: plasmoid.expanded = true }
    Timer { id: closeTimer; interval: 300; onTriggered: if (!hoverCompact && !hoverPopup) plasmoid.expanded = false }

    // ─────────────────────────────────────────────────────────────────────────
    // COMPACT REPRESENTATION
    // ─────────────────────────────────────────────────────────────────────────
    Plasmoid.compactRepresentation: MouseArea {
        id: compactArea
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
        onWheel: {
            var next = wheel.angleDelta.y > 0
                ? (pagerModel.currentPage - 1 + pagerModel.count) % pagerModel.count
                : (pagerModel.currentPage + 1) % pagerModel.count
            pagerModel.changePage(next)
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // FULL REPRESENTATION
    // ─────────────────────────────────────────────────────────────────────────
    Plasmoid.fullRepresentation: Item {
        id: popup

        readonly property int cols: Math.max(1, Math.ceil(Math.sqrt(pagerModel.count)))
        readonly property int rows: Math.max(1, Math.ceil(pagerModel.count / cols))
        readonly property real deskW: 130
        readonly property real deskH: pagerModel.pagerItemSize.height > 0
            ? deskW * pagerModel.pagerItemSize.height / pagerModel.pagerItemSize.width
            : deskW * 9 / 16
        readonly property real scaleX: deskW / Math.max(1, pagerModel.pagerItemSize.width)
        readonly property real scaleY: deskH / Math.max(1, pagerModel.pagerItemSize.height)

        Layout.preferredWidth: cols * (deskW + 8) + 32
        Layout.preferredHeight: rows * (deskH + 8) + 56
        Layout.minimumWidth: 200
        Layout.minimumHeight: 120

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: { hoverPopup = true; closeTimer.stop() }
            onExited: { hoverPopup = false; if (!hoverCompact) closeTimer.start() }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            // ─────────────────────────────────────────────────────────────
            // DESKTOP GRID
            // ─────────────────────────────────────────────────────────────
            Grid {
                id: desktopGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignHCenter
                columns: popup.cols
                spacing: 6

                Repeater {
                    id: repeater
                    model: pagerModel

                    Rectangle {
                        id: desktop
                        width: popup.deskW
                        height: popup.deskH

                        readonly property string desktopName: model.display || ("Desktop " + (index + 1))
                        readonly property bool isActive: index === pagerModel.currentPage

                        color: isActive ? Qt.darker(PlasmaCore.Theme.highlightColor, 1.3) : PlasmaCore.Theme.backgroundColor
                        border.width: isActive ? 2 : 1
                        border.color: isActive ? PlasmaCore.Theme.highlightColor : PlasmaCore.Theme.disabledTextColor
                        radius: 4
                        clip: true

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onEntered: { hoverPopup = true; closeTimer.stop(); parent.opacity = 1 }
                            onExited: parent.opacity = 0.92
                            onClicked: mouse.button === Qt.RightButton ? ctxMenu.popup() : (pagerModel.changePage(index), plasmoid.expanded = false)
                        }

                        opacity: 0.92

                        // ─────────────────────────────────────────────────
                        // WINDOWS with real geometry
                        // ─────────────────────────────────────────────────
                        Item {
                            anchors.fill: parent
                            anchors.margins: 2
                            clip: true
                            visible: showPreviews

                            Repeater {
                                model: TasksModel

                                Rectangle {
                                    readonly property rect geo: model.Geometry
                                    readonly property bool minimized: model.IsMinimized === true

                                    x: Math.round(geo.x * popup.scaleX)
                                    y: Math.round(geo.y * popup.scaleY)
                                    width: Math.max(8, Math.round(geo.width * popup.scaleX))
                                    height: Math.max(6, Math.round(geo.height * popup.scaleY))
                                    visible: !minimized

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

                        // ─────────────────────────────────────────────────
                        // DESKTOP LABEL (centered)
                        // ─────────────────────────────────────────────────
                        Column {
                            anchors.centerIn: parent
                            visible: !showPreviews
                            PlasmaComponents.Label {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: index + 1
                                font.bold: true; font.pixelSize: 18
                                color: desktop.isActive ? PlasmaCore.Theme.highlightedTextColor : PlasmaCore.Theme.textColor
                            }
                            PlasmaComponents.Label {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: desktop.desktopName
                                font.pixelSize: 10
                                color: desktop.isActive ? PlasmaCore.Theme.highlightedTextColor : PlasmaCore.Theme.textColor
                                width: popup.deskW - 10
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        // Badge when previews enabled
                        Rectangle {
                            visible: showPreviews
                            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 3 }
                            width: badgeLbl.implicitWidth + 12; height: badgeLbl.implicitHeight + 4
                            color: Qt.rgba(0,0,0,0.7); radius: 3
                            PlasmaComponents.Label {
                                id: badgeLbl; anchors.centerIn: parent
                                text: (index + 1) + " " + desktop.desktopName
                                font.pixelSize: 11; font.bold: true; color: "white"
                            }
                        }

                        // Context menu
                        Menu {
                            id: ctxMenu
                            MenuItem {
                                text: "Rename..."
                                icon.name: "edit-rename"
                                onTriggered: { renameDlg.idx = index; renameDlg.open(); renameField.text = desktop.desktopName; renameField.selectAll() }
                            }
                            MenuItem {
                                text: "Delete"
                                icon.name: "edit-delete"
                                enabled: pagerModel.count > 1
                                onTriggered: pagerModel.removeDesktop()
                            }
                        }
                    }
                }
            }

            // ─────────────────────────────────────────────────────────────
            // BOTTOM BAR
            // ─────────────────────────────────────────────────────────────
            MouseArea {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                hoverEnabled: true
                onEntered: { hoverPopup = true; closeTimer.stop() }
                onExited: { hoverPopup = false; if (!hoverCompact) closeTimer.start() }

                RowLayout {
                    anchors.fill: parent
                    spacing: 8
                    PlasmaComponents.Button {
                        icon.name: "list-add"; text: "Add"
                        onClicked: pagerModel.addDesktop()
                    }
                    Item { Layout.fillWidth: true }
                    PlasmaComponents.Label {
                        text: pagerModel.count + " desktops"
                        opacity: 0.6; font.pixelSize: 11
                    }
                }
            }
        }

        // ─────────────────────────────────────────────────────────────────
        // RENAME DIALOG
        // ─────────────────────────────────────────────────────────────────
        Dialog {
            id: renameDlg
            property int idx: 0
            title: "Rename Desktop"
            standardButtons: Dialog.Ok | Dialog.Cancel
            anchors.centerIn: parent
            contentItem: PlasmaComponents.TextField {
                id: renameField
                Layout.preferredWidth: 180
                onAccepted: renameDlg.accept()
            }
            onAccepted: {
                if (renameField.text.trim()) {
                    // Use KWin DBus to rename
                    var desktopItem = repeater.itemAt(idx)
                    if (desktopItem) {
                        execSource.connectSource("qdbus org.kde.KWin /VirtualDesktopManager setDesktopName '" +
                            pagerModel.data(pagerModel.index(idx, 0), 0x0100 + 1) + "' '" +
                            renameField.text.trim().replace(/'/g, "'\\''") + "'")
                    }
                    pagerModel.refresh()
                }
            }
        }

        PlasmaCore.DataSource {
            id: execSource
            engine: "executable"
            onNewData: disconnectSource(sourceName)
        }
    }
}
