// DesktopManager.js - Pure logic functions (testeable)
.pragma library

// Build command to remove a desktop
function buildRemoveCommand(desktopId) {
    if (!desktopId) return null
    return "qdbus org.kde.KWin /VirtualDesktopManager removeDesktop '" + desktopId + "'"
}

// Build command to rename a desktop
function buildRenameCommand(desktopId, newName) {
    if (!desktopId || !newName || !newName.trim()) return null
    var escaped = newName.trim().replace(/'/g, "'\\''")
    return "qdbus org.kde.KWin /VirtualDesktopManager setDesktopName '" + desktopId + "' '" + escaped + "'"
}

// Build command to create a desktop
function buildCreateCommand(position, name) {
    var escaped = name.trim().replace(/'/g, "'\\''")
    return "qdbus org.kde.KWin /VirtualDesktopManager createDesktop " + position + " '" + escaped + "'"
}

// Build commands to swap windows between desktops
function buildSwapWindowsCommand(indexA, indexB) {
    return "bash -c 'wins_a=$(wmctrl -l | awk \"\\$2==" + indexA + " {print \\$1}\"); " +
        "wins_b=$(wmctrl -l | awk \"\\$2==" + indexB + " {print \\$1}\"); " +
        "for w in $wins_a; do wmctrl -i -r $w -t " + indexB + "; done; " +
        "for w in $wins_b; do wmctrl -i -r $w -t " + indexA + "; done'"
}

// Escape string for shell
function escapeShell(str) {
    return str.replace(/'/g, "'\\''")
}

// Calculate grid dimensions
function calculateGrid(count) {
    var cols = Math.max(1, Math.ceil(Math.sqrt(count)))
    var rows = Math.max(1, Math.ceil(count / cols))
    return { cols: cols, rows: rows }
}

// Calculate desktop preview dimensions
function calculatePreviewSize(baseSize, screenWidth, screenHeight) {
    var width = baseSize
    var height = screenHeight > 0 ? baseSize * screenHeight / screenWidth : baseSize * 9 / 16
    return { width: width, height: height }
}

// Calculate scale factors for window positioning
function calculateScale(previewWidth, previewHeight, screenWidth, screenHeight) {
    return {
        x: previewWidth / Math.max(1, screenWidth),
        y: previewHeight / Math.max(1, screenHeight)
    }
}

// Validate swap operation
function canSwap(indexA, indexB, count) {
    return indexA >= 0 && indexB >= 0 &&
           indexA < count && indexB < count &&
           indexA !== indexB
}

// Calculate next desktop (for wheel navigation)
function nextDesktop(current, count, direction) {
    if (direction > 0) {
        return (current + 1) % count
    } else {
        return (current - 1 + count) % count
    }
}
