import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.19 as Kirigami

Kirigami.FormLayout {
    id: page

    property alias cfg_showWindowPreviews: showWindowPreviews.checked
    property alias cfg_showWindowIcons: showWindowIcons.checked
    property alias cfg_previewSize: previewSize.value

    CheckBox {
        id: showWindowPreviews
        Kirigami.FormData.label: i18n("Window Previews:")
        text: i18n("Show window outlines in popup")
    }

    CheckBox {
        id: showWindowIcons
        Kirigami.FormData.label: i18n("Window Icons:")
        text: i18n("Show application icons on windows")
        enabled: showWindowPreviews.checked
    }

    SpinBox {
        id: previewSize
        Kirigami.FormData.label: i18n("Preview Size:")
        from: 40
        to: 150
        stepSize: 10
        enabled: showWindowPreviews.checked

        textFromValue: function(value) {
            return value + " px"
        }
    }
}
