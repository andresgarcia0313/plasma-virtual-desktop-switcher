pragma Singleton
import QtQuick 2.15

QtObject {
    readonly property string lang: Qt.locale().name.substring(0, 2)

    readonly property var strings: ({
        "en": {
            desktop: "Desktop", add: "Add", desktops: "desktops",
            rename: "Rename...", delete_: "Delete",
            renameTitle: "Rename Desktop", switchTo: "Switch to",
            newDesktop: "New Desktop", enterName: "Enter name:",
            create: "Create", cancel: "Cancel", save: "Save"
        },
        "es": {
            desktop: "Escritorio", add: "Agregar", desktops: "escritorios",
            rename: "Renombrar...", delete_: "Eliminar",
            renameTitle: "Renombrar Escritorio", switchTo: "Cambiar a",
            newDesktop: "Nuevo Escritorio", enterName: "Ingrese nombre:",
            create: "Crear", cancel: "Cancelar", save: "Guardar"
        },
        "zh": {
            desktop: "桌面", add: "添加", desktops: "个桌面",
            rename: "重命名...", delete_: "删除",
            renameTitle: "重命名桌面", switchTo: "切换到",
            newDesktop: "新建桌面", enterName: "输入名称:",
            create: "创建", cancel: "取消", save: "保存"
        },
        "fr": {
            desktop: "Bureau", add: "Ajouter", desktops: "bureaux",
            rename: "Renommer...", delete_: "Supprimer",
            renameTitle: "Renommer le bureau", switchTo: "Basculer vers",
            newDesktop: "Nouveau bureau", enterName: "Entrez le nom:",
            create: "Créer", cancel: "Annuler", save: "Enregistrer"
        },
        "de": {
            desktop: "Desktop", add: "Hinzufügen", desktops: "Desktops",
            rename: "Umbenennen...", delete_: "Löschen",
            renameTitle: "Desktop umbenennen", switchTo: "Wechseln zu",
            newDesktop: "Neuer Desktop", enterName: "Name eingeben:",
            create: "Erstellen", cancel: "Abbrechen", save: "Speichern"
        },
        "pt": {
            desktop: "Área de trabalho", add: "Adicionar", desktops: "áreas",
            rename: "Renomear...", delete_: "Excluir",
            renameTitle: "Renomear", switchTo: "Mudar para",
            newDesktop: "Nova área", enterName: "Digite o nome:",
            create: "Criar", cancel: "Cancelar", save: "Salvar"
        }
    })

    readonly property var t: strings[lang] || strings["en"]
}
