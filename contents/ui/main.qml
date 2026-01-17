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
    // INTERNATIONALIZATION (i18n)
    // ─────────────────────────────────────────────────────────────────────────
    readonly property string systemLang: Qt.locale().name.substring(0, 2)
    readonly property var translations: ({
        "en": { desktop: "Desktop", add: "Add", desktops: "desktops", rename: "Rename...", delete_: "Delete",
                renameTitle: "Rename Desktop", switchTo: "Switch to", moveWindowHere: "Move window here",
                newDesktop: "New Desktop", confirmDelete: "Delete this desktop?" },
        "es": { desktop: "Escritorio", add: "Agregar", desktops: "escritorios", rename: "Renombrar...", delete_: "Eliminar",
                renameTitle: "Renombrar Escritorio", switchTo: "Cambiar a", moveWindowHere: "Mover ventana aquí",
                newDesktop: "Nuevo Escritorio", confirmDelete: "¿Eliminar este escritorio?" },
        "zh": { desktop: "桌面", add: "添加", desktops: "个桌面", rename: "重命名...", delete_: "删除",
                renameTitle: "重命名桌面", switchTo: "切换到", moveWindowHere: "移动窗口到此处",
                newDesktop: "新建桌面", confirmDelete: "删除此桌面？" },
        "fr": { desktop: "Bureau", add: "Ajouter", desktops: "bureaux", rename: "Renommer...", delete_: "Supprimer",
                renameTitle: "Renommer le bureau", switchTo: "Basculer vers", moveWindowHere: "Déplacer la fenêtre ici",
                newDesktop: "Nouveau bureau", confirmDelete: "Supprimer ce bureau ?" },
        "de": { desktop: "Desktop", add: "Hinzufügen", desktops: "Desktops", rename: "Umbenennen...", delete_: "Löschen",
                renameTitle: "Desktop umbenennen", switchTo: "Wechseln zu", moveWindowHere: "Fenster hierher verschieben",
                newDesktop: "Neuer Desktop", confirmDelete: "Diesen Desktop löschen?" },
        "pt": { desktop: "Área de trabalho", add: "Adicionar", desktops: "áreas de trabalho", rename: "Renomear...", delete_: "Excluir",
                renameTitle: "Renomear área de trabalho", switchTo: "Mudar para", moveWindowHere: "Mover janela para cá",
                newDesktop: "Nova área de trabalho", confirmDelete: "Excluir esta área de trabalho?" }
    })
    readonly property var t: translations[systemLang] || translations["en"]

    // ─────────────────────────────────────────────────────────────────────────
    // CONFIGURATION
    // ─────────────────────────────────────────────────────────────────────────
    readonly property bool showPreviews: plasmoid.configuration.showWindowPreviews
    readonly property bool showIcons: plasmoid.configuration.showWindowIcons
    readonly property int previewSize: plasmoid.configuration.previewSize || 130

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
            return name || (t.desktop + " " + (pagerModel.currentPage + 1))
        }
        return t.desktop
    }

    function addDesktop() { pagerModel.addDesktop() }
    function removeDesktop(index) {
        if (pagerModel.count > 1) {
            pagerModel.changePage(index)
            pagerModel.removeDesktop()
        }
    }

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
        readonly property real deskW: previewSize
        readonly property real deskH: pagerModel.pagerItemSize.height > 0
            ? deskW * pagerModel.pagerItemSize.height / pagerModel.pagerItemSize.width
            : deskW * 9 / 16
        readonly property real scaleX: deskW / Math.max(1, pagerModel.pagerItemSize.width)
        readonly property real scaleY: deskH / Math.max(1, pagerModel.pagerItemSize.height)

        Layout.preferredWidth: cols * (deskW + 8) + 32
        Layout.preferredHeight: rows * (deskH + 8) + 70
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

                        readonly property string desktopName: model.display || (t.desktop + " " + (index + 1))
                        readonly property bool isActive: index === pagerModel.currentPage
                        property bool isHovered: false

                        color: isActive ? Qt.darker(PlasmaCore.Theme.highlightColor, 1.3) : PlasmaCore.Theme.backgroundColor
                        border.width: isActive ? 2 : 1
                        border.color: isActive ? PlasmaCore.Theme.highlightColor : PlasmaCore.Theme.disabledTextColor
                        radius: 4
                        clip: true
                        opacity: isHovered ? 1 : 0.92

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onEntered: { hoverPopup = true; closeTimer.stop(); desktop.isHovered = true }
                            onExited: { desktop.isHovered = false }
                            onClicked: {
                                if (mouse.button === Qt.RightButton) {
                                    ctxMenu.desktopIndex = index
                                    ctxMenu.desktopName = desktop.desktopName
                                    ctxMenu.popup()
                                } else {
                                    pagerModel.changePage(index)
                                    plasmoid.expanded = false
                                }
                            }
                        }

                        // ─────────────────────────────────────────────────
                        // DELETE BUTTON (top-right, on hover)
                        // ─────────────────────────────────────────────────
                        Rectangle {
                            id: deleteBtn
                            visible: desktop.isHovered && pagerModel.count > 1
                            anchors { top: parent.top; right: parent.right; margins: 2 }
                            width: Math.min(parent.width * 0.25, 44)
                            height: width
                            radius: width / 2
                            color: deleteMouseArea.containsMouse ? "#e74c3c" : Qt.rgba(0,0,0,0.6)

                            PlasmaCore.IconItem {
                                anchors.centerIn: parent
                                width: parent.width * 0.6
                                height: width
                                source: "edit-delete"
                                usesPlasmaTheme: false
                            }

                            MouseArea {
                                id: deleteMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: removeDesktop(index)
                            }
                        }

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
                        // DESKTOP LABEL (centered, when no previews)
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
                        icon.name: "list-add"; text: t.add
                        onClicked: pagerModel.addDesktop()
                    }
                    Item { Layout.fillWidth: true }
                    PlasmaComponents.Label {
                        text: pagerModel.count + " " + t.desktops
                        opacity: 0.6; font.pixelSize: 11
                    }

                    // ─────────────────────────────────────────────────
                    // RESIZE HANDLE
                    // ─────────────────────────────────────────────────
                    Rectangle {
                        width: 20; height: 20
                        color: "transparent"

                        PlasmaCore.IconItem {
                            anchors.fill: parent
                            source: "transform-scale"
                            opacity: resizeMouseArea.containsMouse ? 1 : 0.5
                        }

                        MouseArea {
                            id: resizeMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.SizeFDiagCursor

                            property real startX: 0
                            property real startY: 0
                            property int startSize: 0

                            onPressed: {
                                startX = mouse.x
                                startY = mouse.y
                                startSize = previewSize
                            }
                            onPositionChanged: {
                                if (pressed) {
                                    var delta = (mouse.x - startX + mouse.y - startY) / 2
                                    var newSize = Math.max(80, Math.min(200, startSize + delta))
                                    plasmoid.configuration.previewSize = Math.round(newSize)
                                }
                            }
                        }
                    }
                }
            }
        }

        // ─────────────────────────────────────────────────────────────────
        // CONTEXT MENU
        // ─────────────────────────────────────────────────────────────────
        Menu {
            id: ctxMenu
            property int desktopIndex: 0
            property string desktopName: ""

            MenuItem {
                text: t.switchTo + " \"" + ctxMenu.desktopName + "\""
                icon.name: "go-jump"
                onTriggered: {
                    pagerModel.changePage(ctxMenu.desktopIndex)
                    plasmoid.expanded = false
                }
            }
            MenuSeparator {}
            MenuItem {
                text: t.rename
                icon.name: "edit-rename"
                onTriggered: {
                    renameDlg.idx = ctxMenu.desktopIndex
                    renameDlg.open()
                    renameField.text = ctxMenu.desktopName
                    renameField.selectAll()
                }
            }
            MenuItem {
                text: t.delete_
                icon.name: "edit-delete"
                enabled: pagerModel.count > 1
                onTriggered: removeDesktop(ctxMenu.desktopIndex)
            }
            MenuSeparator {}
            MenuItem {
                text: t.newDesktop
                icon.name: "list-add"
                onTriggered: pagerModel.addDesktop()
            }
        }

        // ─────────────────────────────────────────────────────────────────
        // RENAME DIALOG
        // ─────────────────────────────────────────────────────────────────
        Dialog {
            id: renameDlg
            property int idx: 0
            title: t.renameTitle
            standardButtons: Dialog.Ok | Dialog.Cancel
            anchors.centerIn: parent
            contentItem: PlasmaComponents.TextField {
                id: renameField
                Layout.preferredWidth: 180
                onAccepted: renameDlg.accept()
            }
            onAccepted: {
                if (renameField.text.trim()) {
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
