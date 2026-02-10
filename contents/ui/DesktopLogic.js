// DesktopLogic.js - Pure business logic (testable with Node.js)
// All functions are pure - no side effects, same input = same output
.pragma library

// ============================================================================
// COMMAND BUILDERS - Generate shell commands for KWin D-Bus operations
// ============================================================================

/**
 * Build command to remove a desktop
 * @param {string} desktopId - The desktop UUID
 * @returns {string|null} - Command string or null if invalid
 */
function buildRemoveCommand(desktopId) {
    if (!desktopId || typeof desktopId !== 'string' || desktopId.trim() === '') {
        return null
    }
    return "qdbus org.kde.KWin /VirtualDesktopManager removeDesktop '" + desktopId + "'"
}

/**
 * Build command to rename a desktop
 * @param {string} desktopId - The desktop UUID
 * @param {string} newName - The new name
 * @returns {string|null} - Command string or null if invalid
 */
function buildRenameCommand(desktopId, newName) {
    if (!desktopId || typeof desktopId !== 'string' || desktopId.trim() === '') {
        return null
    }
    if (!newName || typeof newName !== 'string' || newName.trim() === '') {
        return null
    }
    var escaped = escapeShell(newName.trim())
    return "qdbus org.kde.KWin /VirtualDesktopManager setDesktopName '" + desktopId + "' '" + escaped + "'"
}

/**
 * Build command to create a new desktop
 * @param {number} position - Position index for new desktop
 * @param {string} name - Name for new desktop
 * @returns {string} - Command string
 */
function buildCreateCommand(position, name) {
    var pos = Math.max(0, Math.floor(position))
    var escaped = escapeShell(name ? name.trim() : 'Desktop')
    return "qdbus org.kde.KWin /VirtualDesktopManager createDesktop " + pos + " '" + escaped + "'"
}

/**
 * Build bash command to swap windows between two desktops using wmctrl
 * @param {number} indexA - First desktop index (0-based)
 * @param {number} indexB - Second desktop index (0-based)
 * @returns {string} - Bash command string
 */
function buildSwapWindowsCommand(indexA, indexB) {
    var a = Math.floor(indexA)
    var b = Math.floor(indexB)
    return "bash -c 'wins_a=$(wmctrl -l | awk \"\\$2==" + a + " {print \\$1}\"); " +
           "wins_b=$(wmctrl -l | awk \"\\$2==" + b + " {print \\$1}\"); " +
           "for w in $wins_a; do wmctrl -i -r $w -t " + b + "; done; " +
           "for w in $wins_b; do wmctrl -i -r $w -t " + a + "; done'"
}

// ============================================================================
// STRING UTILITIES
// ============================================================================

/**
 * Escape string for safe use in shell single quotes
 * @param {string} str - Input string
 * @returns {string} - Escaped string
 */
function escapeShell(str) {
    if (!str || typeof str !== 'string') return ''
    return str.replace(/'/g, "'\\''")
}

// ============================================================================
// GRID CALCULATIONS - Pure math functions for layout
// ============================================================================

/**
 * Calculate optimal grid dimensions for N items
 * Uses square root to create balanced grid
 * @param {number} count - Number of items
 * @returns {{cols: number, rows: number}} - Grid dimensions
 */
function calculateGrid(count) {
    var n = Math.max(1, Math.floor(count))
    var cols = Math.max(1, Math.ceil(Math.sqrt(n)))
    var rows = Math.max(1, Math.ceil(n / cols))
    return { cols: cols, rows: rows }
}

/**
 * Calculate preview height maintaining aspect ratio
 * @param {number} width - Preview width
 * @param {number} screenWidth - Screen width
 * @param {number} screenHeight - Screen height
 * @returns {number} - Calculated height
 */
function calculatePreviewHeight(width, screenWidth, screenHeight) {
    if (!screenWidth || screenWidth <= 0 || !screenHeight || screenHeight <= 0) {
        return width * 9 / 16  // Default 16:9
    }
    return width * screenHeight / screenWidth
}

/**
 * Calculate scale factors for positioning windows in preview
 * @param {number} previewWidth - Preview width
 * @param {number} previewHeight - Preview height
 * @param {number} screenWidth - Screen width
 * @param {number} screenHeight - Screen height
 * @returns {{x: number, y: number}} - Scale factors
 */
function calculateScale(previewWidth, previewHeight, screenWidth, screenHeight) {
    return {
        x: previewWidth / Math.max(1, screenWidth),
        y: previewHeight / Math.max(1, screenHeight)
    }
}

// ============================================================================
// NAVIGATION - Desktop switching logic
// ============================================================================

/**
 * Calculate next desktop index with wrap-around
 * @param {number} current - Current desktop index
 * @param {number} count - Total number of desktops
 * @param {number} direction - Direction: positive = forward, negative = backward
 * @returns {number} - Next desktop index
 */
function nextDesktop(current, count, direction) {
    if (count <= 0) return 0
    var c = Math.max(0, Math.floor(current))
    var n = Math.max(1, Math.floor(count))

    if (direction > 0) {
        return (c + 1) % n
    } else {
        return (c - 1 + n) % n
    }
}

// ============================================================================
// DRAG AND DROP - Validation and detection
// ============================================================================

/**
 * Check if swap operation is valid
 * @param {number} indexA - Source index
 * @param {number} indexB - Target index
 * @param {number} count - Total count
 * @returns {boolean} - True if swap is valid
 */
function canSwap(indexA, indexB, count) {
    if (typeof indexA !== 'number' || typeof indexB !== 'number' || typeof count !== 'number') {
        return false
    }
    return indexA >= 0 && indexB >= 0 &&
           indexA < count && indexB < count &&
           indexA !== indexB
}

/**
 * Find drop target index from mouse position
 * This function needs QML objects, returns -1 for pure JS testing
 * @param {object} repeater - QML Repeater
 * @param {object} grid - QML Grid
 * @param {number} mouseX - Mouse X in grid coordinates
 * @param {number} mouseY - Mouse Y in grid coordinates
 * @returns {number} - Target index or -1
 */
function findDropTarget(repeater, grid, mouseX, mouseY) {
    if (!repeater || !grid || typeof repeater.count !== 'number') {
        return -1
    }

    for (var i = 0; i < repeater.count; i++) {
        var item = repeater.itemAt(i)
        if (!item) continue

        var itemPos = grid.mapFromItem(item, 0, 0)
        if (mouseX >= itemPos.x && mouseX < itemPos.x + item.width &&
            mouseY >= itemPos.y && mouseY < itemPos.y + item.height) {
            return i
        }
    }
    return -1
}

/**
 * Calculate distance between two points
 * @param {number} x1 - First point X
 * @param {number} y1 - First point Y
 * @param {number} x2 - Second point X
 * @param {number} y2 - Second point Y
 * @returns {number} - Distance
 */
function distance(x1, y1, x2, y2) {
    return Math.sqrt(Math.pow(x2 - x1, 2) + Math.pow(y2 - y1, 2))
}

/**
 * Check if drag threshold is exceeded
 * @param {number} startX - Start X
 * @param {number} startY - Start Y
 * @param {number} currentX - Current X
 * @param {number} currentY - Current Y
 * @param {number} threshold - Drag threshold (default 10)
 * @returns {boolean} - True if threshold exceeded
 */
function isDragStarted(startX, startY, currentX, currentY, threshold) {
    var t = threshold || 10
    return distance(startX, startY, currentX, currentY) > t
}

// ============================================================================
// VALIDATION - Input validation helpers
// ============================================================================

/**
 * Validate desktop index
 * @param {number} index - Index to validate
 * @param {number} count - Total count
 * @returns {boolean} - True if valid
 */
function isValidIndex(index, count) {
    return typeof index === 'number' &&
           typeof count === 'number' &&
           index >= 0 &&
           index < count &&
           Number.isInteger(index)
}

/**
 * Validate desktop name
 * @param {string} name - Name to validate
 * @returns {boolean} - True if valid
 */
function isValidName(name) {
    return typeof name === 'string' && name.trim().length > 0
}

/**
 * Clamp value between min and max
 * @param {number} value - Value to clamp
 * @param {number} min - Minimum
 * @param {number} max - Maximum
 * @returns {number} - Clamped value
 */
function clamp(value, min, max) {
    return Math.max(min, Math.min(max, value))
}
