# Virtual Desktop Switcher

[English](#english) | [Español](#español) | [中文](#中文)

![Virtual Desktop Switcher Widget](screenshots/widget-preview.png)

---

## English

A KDE Plasma 5 widget that displays the current virtual desktop name and provides a visual overview of all desktops with real window positions.

![Plasma 5.27+](https://img.shields.io/badge/Plasma-5.27%2B-blue)
![License GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-green)
![QML](https://img.shields.io/badge/QML-Qt%205.15-orange)

### Features

- **Real-time desktop name** in panel - Shows active virtual desktop name
- **Hover to open** - Popup appears automatically when hovering (80ms delay)
- **Real window geometry** - Windows displayed in actual positions using native KDE pager API
- **Window icons** - Application icons shown inside window previews
- **Proper aspect ratio** - Desktop previews match your screen proportions
- **Grid layout** - Automatically arranges desktops in optimal columns/rows
- **Desktop management**:
  - Click to switch desktop
  - Right-click to rename or delete
  - Add new desktops with "Add" button
  - Scroll wheel to cycle through desktops
- **High performance** - Uses native `PagerModel` instead of shell commands

### Installation

```bash
# Clone the repository
git clone https://github.com/andresgarcia0313/plasma-virtual-desktop-switcher.git

# Copy to Plasma plasmoids directory
cp -r plasma-virtual-desktop-switcher ~/.local/share/plasma/plasmoids/org.kde.virtualdesktopswitcher

# Restart Plasma
kquitapp5 plasmashell && kstart5 plasmashell
```

### Add to Panel

1. Right-click on your panel → **Add Widgets**
2. Search for **"Virtual Desktop Switcher"**
3. Drag to your panel

### Configuration

Right-click on the widget → **Configure Virtual Desktop Switcher**

| Option | Description |
|--------|-------------|
| Show window previews | Display window outlines inside desktop previews |
| Show window icons | Display application icons on window rectangles |

### Usage

| Action | Result |
|--------|--------|
| **Hover** | Opens desktop overview popup |
| **Click** on desktop | Switches to that desktop |
| **Right-click** on desktop | Context menu (Rename, Delete) |
| **Scroll wheel** | Cycles through desktops |
| **Add button** | Creates new virtual desktop |

### Requirements

- KDE Plasma 5.27 or later
- KWin window manager
- Qt 5.15+

---

## Español

Un widget de KDE Plasma 5 que muestra el nombre del escritorio virtual actual y proporciona una vista general de todos los escritorios con las posiciones reales de las ventanas.

### Características

- **Nombre del escritorio en tiempo real** en el panel - Muestra el nombre del escritorio virtual activo
- **Abrir al pasar el mouse** - El popup aparece automáticamente al pasar el cursor (80ms de retraso)
- **Geometría real de ventanas** - Las ventanas se muestran en sus posiciones reales usando la API nativa del pager de KDE
- **Iconos de ventanas** - Iconos de aplicaciones mostrados dentro de las previsualizaciones
- **Relación de aspecto correcta** - Las previsualizaciones coinciden con las proporciones de tu pantalla
- **Diseño en cuadrícula** - Organiza automáticamente los escritorios en columnas/filas óptimas
- **Gestión de escritorios**:
  - Clic para cambiar de escritorio
  - Clic derecho para renombrar o eliminar
  - Agregar nuevos escritorios con el botón "Add"
  - Rueda del mouse para navegar entre escritorios
- **Alto rendimiento** - Usa `PagerModel` nativo en lugar de comandos de shell

### Instalación

```bash
# Clonar el repositorio
git clone https://github.com/andresgarcia0313/plasma-virtual-desktop-switcher.git

# Copiar al directorio de plasmoids de Plasma
cp -r plasma-virtual-desktop-switcher ~/.local/share/plasma/plasmoids/org.kde.virtualdesktopswitcher

# Reiniciar Plasma
kquitapp5 plasmashell && kstart5 plasmashell
```

### Agregar al Panel

1. Clic derecho en el panel → **Añadir elementos gráficos**
2. Buscar **"Virtual Desktop Switcher"**
3. Arrastrar al panel

### Configuración

Clic derecho en el widget → **Configurar Virtual Desktop Switcher**

| Opción | Descripción |
|--------|-------------|
| Mostrar previsualizaciones | Mostrar contornos de ventanas dentro de las previsualizaciones |
| Mostrar iconos de ventanas | Mostrar iconos de aplicaciones en los rectángulos de ventanas |

### Uso

| Acción | Resultado |
|--------|-----------|
| **Pasar el mouse** | Abre el popup de vista general |
| **Clic** en escritorio | Cambia a ese escritorio |
| **Clic derecho** en escritorio | Menú contextual (Renombrar, Eliminar) |
| **Rueda del mouse** | Navega entre escritorios |
| **Botón Add** | Crea nuevo escritorio virtual |

### Requisitos

- KDE Plasma 5.27 o posterior
- Gestor de ventanas KWin
- Qt 5.15+

---

## 中文

一个 KDE Plasma 5 小部件，显示当前虚拟桌面名称，并提供所有桌面的可视化概览，包含真实的窗口位置。

### 功能特点

- **实时桌面名称** - 在面板中显示当前活动的虚拟桌面名称
- **悬停打开** - 鼠标悬停时自动显示弹出窗口（80毫秒延迟）
- **真实窗口位置** - 使用 KDE 原生 pager API 显示窗口的实际位置
- **窗口图标** - 在窗口预览中显示应用程序图标
- **正确的宽高比** - 桌面预览匹配您的屏幕比例
- **网格布局** - 自动以最佳列/行排列桌面
- **桌面管理**：
  - 点击切换桌面
  - 右键重命名或删除
  - 使用"Add"按钮添加新桌面
  - 滚轮在桌面间循环切换
- **高性能** - 使用原生 `PagerModel` 而非 shell 命令

### 安装

```bash
# 克隆仓库
git clone https://github.com/andresgarcia0313/plasma-virtual-desktop-switcher.git

# 复制到 Plasma plasmoids 目录
cp -r plasma-virtual-desktop-switcher ~/.local/share/plasma/plasmoids/org.kde.virtualdesktopswitcher

# 重启 Plasma
kquitapp5 plasmashell && kstart5 plasmashell
```

### 添加到面板

1. 右键点击面板 → **添加部件**
2. 搜索 **"Virtual Desktop Switcher"**
3. 拖拽到面板

### 配置

右键点击小部件 → **配置 Virtual Desktop Switcher**

| 选项 | 描述 |
|------|------|
| 显示窗口预览 | 在桌面预览中显示窗口轮廓 |
| 显示窗口图标 | 在窗口矩形上显示应用程序图标 |

### 使用方法

| 操作 | 结果 |
|------|------|
| **悬停** | 打开桌面概览弹窗 |
| **点击** 桌面 | 切换到该桌面 |
| **右键点击** 桌面 | 上下文菜单（重命名、删除） |
| **滚轮** | 在桌面间循环 |
| **Add 按钮** | 创建新的虚拟桌面 |

### 系统要求

- KDE Plasma 5.27 或更高版本
- KWin 窗口管理器
- Qt 5.15+

---

## Technical Details / Detalles Técnicos / 技术细节

### Architecture

The widget uses the native KDE pager plugin (`org.kde.plasma.private.pager`) which provides:

- `PagerModel` - Virtual desktop model with real-time updates
- `TasksModel` - Window information including geometry
- `pagerItemSize` - Screen dimensions for aspect ratio

### Key Files

```
org.kde.virtualdesktopswitcher/
├── metadata.desktop          # Plugin metadata
├── contents/
│   ├── config/
│   │   ├── main.xml         # Configuration schema
│   │   └── config.qml       # Config page registration
│   └── ui/
│       ├── main.qml         # Main widget code
│       └── configGeneral.qml # Settings UI
```

### QML Imports

```qml
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.private.pager 2.0  // Native pager API
```

### KWin D-Bus API

```bash
# List virtual desktops
qdbus org.kde.KWin /VirtualDesktopManager desktops

# Get current desktop
qdbus org.kde.KWin /VirtualDesktopManager current

# Rename desktop
qdbus org.kde.KWin /VirtualDesktopManager setDesktopName '<id>' 'New Name'

# Create desktop
qdbus org.kde.KWin /VirtualDesktopManager createDesktop <position> 'Name'

# Remove desktop
qdbus org.kde.KWin /VirtualDesktopManager removeDesktop '<id>'
```

---

## License / Licencia / 许可证

GPL-3.0 - See [LICENSE](LICENSE)

## Author / Autor / 作者

**Andres Garcia** - [GitHub](https://github.com/andresgarcia0313)
