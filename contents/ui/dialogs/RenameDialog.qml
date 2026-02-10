import QtQuick 2.15
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import ".." as Local

Rectangle {
    id: root
    visible: false
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.7)
    z: 100

    property int desktopIndex: -1
    signal accepted(int index, string name)
    signal cancelled()

    function open(index, name) {
        desktopIndex = index
        nameField.text = name
        visible = true
        nameField.forceActiveFocus()
        nameField.selectAll()
    }

    function close() {
        visible = false
        cancelled()
    }

    function doRename() {
        if (nameField.text.trim()) {
            accepted(desktopIndex, nameField.text)
            close()
        }
    }

    MouseArea { anchors.fill: parent; onClicked: root.close() }

    Rectangle {
        anchors.centerIn: parent
        width: 280; height: 130
        color: PlasmaCore.Theme.backgroundColor
        border.color: PlasmaCore.Theme.highlightColor
        border.width: 1; radius: 8

        MouseArea { anchors.fill: parent }

        Column {
            anchors.fill: parent; anchors.margins: 16; spacing: 12

            PlasmaComponents.Label {
                text: Local.Translations.t.renameTitle
                font.bold: true; font.pixelSize: 14
            }

            PlasmaComponents.TextField {
                id: nameField
                width: parent.width
                onAccepted: root.doRename()
            }

            Row {
                anchors.right: parent.right; spacing: 8
                PlasmaComponents.Button {
                    text: Local.Translations.t.cancel
                    onClicked: root.close()
                }
                PlasmaComponents.Button {
                    text: Local.Translations.t.save
                    highlighted: true
                    onClicked: root.doRename()
                }
            }
        }
    }
}
