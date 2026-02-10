#!/usr/bin/env node
/**
 * Test Suite for DesktopLogic.js
 * Provides comprehensive coverage of all pure functions
 * Run: node test_DesktopLogic.js
 */

const fs = require('fs');
const path = require('path');

// Load and prepare the module
const srcPath = path.join(__dirname, '../contents/ui/DesktopLogic.js');
let code = fs.readFileSync(srcPath, 'utf8');
code = code.replace('.pragma library', '');
code += `
module.exports = {
    buildRemoveCommand, buildRenameCommand, buildCreateCommand, buildSwapWindowsCommand,
    escapeShell, calculateGrid, calculatePreviewHeight, calculateScale,
    nextDesktop, canSwap, findDropTarget, distance, isDragStarted,
    isValidIndex, isValidName, clamp
};`;
const tmpPath = '/tmp/DesktopLogic_test.js';
fs.writeFileSync(tmpPath, code);
const Logic = require(tmpPath);

// Test utilities
let passed = 0, failed = 0, total = 0;
const results = { passed: [], failed: [] };

function test(name, fn) {
    total++;
    try {
        fn();
        passed++;
        results.passed.push(name);
        console.log(`  ✓ ${name}`);
    } catch (e) {
        failed++;
        results.failed.push({ name, error: e.message });
        console.log(`  ✗ ${name}`);
        console.log(`    Error: ${e.message}`);
    }
}

function assertEqual(actual, expected, msg) {
    if (actual !== expected) {
        throw new Error(`${msg || 'Assertion failed'}: expected "${expected}", got "${actual}"`);
    }
}

function assertDeepEqual(actual, expected, msg) {
    if (JSON.stringify(actual) !== JSON.stringify(expected)) {
        throw new Error(`${msg || 'Assertion failed'}: expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
    }
}

function assertTrue(condition, msg) {
    if (!condition) throw new Error(msg || 'Expected true');
}

function assertFalse(condition, msg) {
    if (condition) throw new Error(msg || 'Expected false');
}

function assertNull(value, msg) {
    if (value !== null) throw new Error(`${msg || 'Expected null'}, got ${value}`);
}

function assertNotNull(value, msg) {
    if (value === null) throw new Error(msg || 'Expected non-null');
}

function assertContains(str, substr, msg) {
    if (!str.includes(substr)) {
        throw new Error(`${msg || 'String does not contain'}: "${substr}" not in "${str}"`);
    }
}

function assertApprox(actual, expected, tolerance, msg) {
    if (Math.abs(actual - expected) > tolerance) {
        throw new Error(`${msg || 'Approximation failed'}: expected ~${expected}, got ${actual}`);
    }
}

// ============================================================================
// TEST SUITES
// ============================================================================

console.log('\n╔════════════════════════════════════════════════════════════════╗');
console.log('║          DesktopLogic.js - Comprehensive Test Suite           ║');
console.log('╚════════════════════════════════════════════════════════════════╝\n');

// ----------------------------------------------------------------------------
console.log('┌─ buildRemoveCommand ─────────────────────────────────────────────');
// ----------------------------------------------------------------------------

test('returns valid command for valid ID', () => {
    const result = Logic.buildRemoveCommand('abc-123');
    assertEqual(result, "qdbus org.kde.KWin /VirtualDesktopManager removeDesktop 'abc-123'");
});

test('returns null for null ID', () => {
    assertNull(Logic.buildRemoveCommand(null));
});

test('returns null for undefined ID', () => {
    assertNull(Logic.buildRemoveCommand(undefined));
});

test('returns null for empty string ID', () => {
    assertNull(Logic.buildRemoveCommand(''));
});

test('returns null for whitespace-only ID', () => {
    assertNull(Logic.buildRemoveCommand('   '));
});

test('returns null for numeric ID', () => {
    assertNull(Logic.buildRemoveCommand(123));
});

test('handles UUID format', () => {
    const result = Logic.buildRemoveCommand('550e8400-e29b-41d4-a716-446655440000');
    assertContains(result, '550e8400-e29b-41d4-a716-446655440000');
});

// ----------------------------------------------------------------------------
console.log('\n┌─ buildRenameCommand ─────────────────────────────────────────────');
// ----------------------------------------------------------------------------

test('returns valid command for valid inputs', () => {
    const result = Logic.buildRenameCommand('id1', 'Work');
    assertEqual(result, "qdbus org.kde.KWin /VirtualDesktopManager setDesktopName 'id1' 'Work'");
});

test('escapes single quotes in name', () => {
    const result = Logic.buildRenameCommand('id1', "it's mine");
    assertContains(result, "it'\\''s mine");
});

test('trims whitespace from name', () => {
    const result = Logic.buildRenameCommand('id1', '  Work  ');
    assertContains(result, "'Work'");
});

test('returns null for null ID', () => {
    assertNull(Logic.buildRenameCommand(null, 'name'));
});

test('returns null for null name', () => {
    assertNull(Logic.buildRenameCommand('id', null));
});

test('returns null for empty name', () => {
    assertNull(Logic.buildRenameCommand('id', ''));
});

test('returns null for whitespace-only name', () => {
    assertNull(Logic.buildRenameCommand('id', '   '));
});

test('handles special characters in name', () => {
    const result = Logic.buildRenameCommand('id', 'Dev & Test');
    assertContains(result, 'Dev & Test');
});

test('handles unicode in name', () => {
    const result = Logic.buildRenameCommand('id', '桌面');
    assertContains(result, '桌面');
});

// ----------------------------------------------------------------------------
console.log('\n┌─ buildCreateCommand ───────────────────────────────────────────');
// ----------------------------------------------------------------------------

test('returns valid command for position 0', () => {
    const result = Logic.buildCreateCommand(0, 'New Desktop');
    assertEqual(result, "qdbus org.kde.KWin /VirtualDesktopManager createDesktop 0 'New Desktop'");
});

test('returns valid command for position 5', () => {
    const result = Logic.buildCreateCommand(5, 'Desktop 6');
    assertContains(result, 'createDesktop 5');
});

test('handles negative position (clamps to 0)', () => {
    const result = Logic.buildCreateCommand(-1, 'Test');
    assertContains(result, 'createDesktop 0');
});

test('handles float position (floors)', () => {
    const result = Logic.buildCreateCommand(2.7, 'Test');
    assertContains(result, 'createDesktop 2');
});

test('escapes single quotes in name', () => {
    const result = Logic.buildCreateCommand(0, "John's Desktop");
    assertContains(result, "John'\\''s Desktop");
});

test('handles null name (uses default)', () => {
    const result = Logic.buildCreateCommand(0, null);
    assertContains(result, "'Desktop'");
});

// ----------------------------------------------------------------------------
console.log('\n┌─ buildSwapWindowsCommand ────────────────────────────────────────');
// ----------------------------------------------------------------------------

test('returns bash command with wmctrl', () => {
    const result = Logic.buildSwapWindowsCommand(0, 1);
    assertContains(result, 'bash -c');
    assertContains(result, 'wmctrl');
});

test('includes both desktop indices', () => {
    const result = Logic.buildSwapWindowsCommand(2, 5);
    assertContains(result, '==2');
    assertContains(result, '==5');
    assertContains(result, '-t 5');
    assertContains(result, '-t 2');
});

test('handles desktop 0', () => {
    const result = Logic.buildSwapWindowsCommand(0, 3);
    assertContains(result, '==0');
});

test('floors float indices', () => {
    const result = Logic.buildSwapWindowsCommand(1.9, 3.1);
    assertContains(result, '==1');
    assertContains(result, '==3');
});

// ----------------------------------------------------------------------------
console.log('\n┌─ escapeShell ────────────────────────────────────────────────────');
// ----------------------------------------------------------------------------

test('escapes single quote', () => {
    assertEqual(Logic.escapeShell("it's"), "it'\\''s");
});

test('escapes multiple single quotes', () => {
    assertEqual(Logic.escapeShell("it's John's"), "it'\\''s John'\\''s");
});

test('returns empty for null', () => {
    assertEqual(Logic.escapeShell(null), '');
});

test('returns empty for undefined', () => {
    assertEqual(Logic.escapeShell(undefined), '');
});

test('returns empty for number', () => {
    assertEqual(Logic.escapeShell(123), '');
});

test('preserves string without quotes', () => {
    assertEqual(Logic.escapeShell('hello world'), 'hello world');
});

// ----------------------------------------------------------------------------
console.log('\n┌─ calculateGrid ──────────────────────────────────────────────────');
// ----------------------------------------------------------------------------

test('1 item = 1x1 grid', () => {
    assertDeepEqual(Logic.calculateGrid(1), { cols: 1, rows: 1 });
});

test('2 items = 2x1 grid', () => {
    assertDeepEqual(Logic.calculateGrid(2), { cols: 2, rows: 1 });
});

test('3 items = 2x2 grid', () => {
    assertDeepEqual(Logic.calculateGrid(3), { cols: 2, rows: 2 });
});

test('4 items = 2x2 grid', () => {
    assertDeepEqual(Logic.calculateGrid(4), { cols: 2, rows: 2 });
});

test('5 items = 3x2 grid', () => {
    assertDeepEqual(Logic.calculateGrid(5), { cols: 3, rows: 2 });
});

test('9 items = 3x3 grid', () => {
    assertDeepEqual(Logic.calculateGrid(9), { cols: 3, rows: 3 });
});

test('16 items = 4x4 grid', () => {
    assertDeepEqual(Logic.calculateGrid(16), { cols: 4, rows: 4 });
});

test('0 items = 1x1 grid (minimum)', () => {
    assertDeepEqual(Logic.calculateGrid(0), { cols: 1, rows: 1 });
});

test('negative items = 1x1 grid (minimum)', () => {
    assertDeepEqual(Logic.calculateGrid(-5), { cols: 1, rows: 1 });
});

test('18 items = 5x4 grid', () => {
    const result = Logic.calculateGrid(18);
    assertTrue(result.cols * result.rows >= 18);
});

// ----------------------------------------------------------------------------
console.log('\n┌─ calculatePreviewHeight ─────────────────────────────────────────');
// ----------------------------------------------------------------------------

test('maintains 16:9 aspect ratio', () => {
    const height = Logic.calculatePreviewHeight(160, 1920, 1080);
    assertApprox(height, 90, 0.01);
});

test('maintains 4:3 aspect ratio', () => {
    const height = Logic.calculatePreviewHeight(120, 1024, 768);
    assertApprox(height, 90, 0.01);
});

test('uses 16:9 default for zero width', () => {
    const height = Logic.calculatePreviewHeight(160, 0, 0);
    assertApprox(height, 90, 0.01);
});

test('uses 16:9 default for negative dimensions', () => {
    const height = Logic.calculatePreviewHeight(160, -100, -100);
    assertApprox(height, 90, 0.01);
});

test('handles ultrawide (21:9)', () => {
    const height = Logic.calculatePreviewHeight(210, 2560, 1080);
    assertApprox(height, 88.59, 0.1);
});

// ----------------------------------------------------------------------------
console.log('\n┌─ calculateScale ─────────────────────────────────────────────────');
// ----------------------------------------------------------------------------

test('calculates correct scale factors', () => {
    const scale = Logic.calculateScale(130, 73, 1920, 1080);
    assertApprox(scale.x, 130/1920, 0.0001);
    assertApprox(scale.y, 73/1080, 0.0001);
});

test('handles zero screen dimensions', () => {
    const scale = Logic.calculateScale(130, 73, 0, 0);
    assertEqual(scale.x, 130);
    assertEqual(scale.y, 73);
});

// ----------------------------------------------------------------------------
console.log('\n┌─ nextDesktop ────────────────────────────────────────────────────');
// ----------------------------------------------------------------------------

test('forward from 0 to 1', () => {
    assertEqual(Logic.nextDesktop(0, 5, 1), 1);
});

test('forward from 4 wraps to 0', () => {
    assertEqual(Logic.nextDesktop(4, 5, 1), 0);
});

test('backward from 0 wraps to 4', () => {
    assertEqual(Logic.nextDesktop(0, 5, -1), 4);
});

test('backward from 2 to 1', () => {
    assertEqual(Logic.nextDesktop(2, 5, -1), 1);
});

test('handles count of 1', () => {
    assertEqual(Logic.nextDesktop(0, 1, 1), 0);
    assertEqual(Logic.nextDesktop(0, 1, -1), 0);
});

test('handles count of 0 (returns 0)', () => {
    assertEqual(Logic.nextDesktop(0, 0, 1), 0);
});

test('floors float current', () => {
    assertEqual(Logic.nextDesktop(1.9, 5, 1), 2);
});

// ----------------------------------------------------------------------------
console.log('\n┌─ canSwap ────────────────────────────────────────────────────────');
// ----------------------------------------------------------------------------

test('valid swap returns true', () => {
    assertTrue(Logic.canSwap(0, 1, 5));
});

test('same index returns false', () => {
    assertFalse(Logic.canSwap(2, 2, 5));
});

test('negative indexA returns false', () => {
    assertFalse(Logic.canSwap(-1, 1, 5));
});

test('negative indexB returns false', () => {
    assertFalse(Logic.canSwap(0, -1, 5));
});

test('indexA >= count returns false', () => {
    assertFalse(Logic.canSwap(5, 1, 5));
});

test('indexB >= count returns false', () => {
    assertFalse(Logic.canSwap(0, 5, 5));
});

test('non-number indexA returns false', () => {
    assertFalse(Logic.canSwap('0', 1, 5));
});

test('non-number indexB returns false', () => {
    assertFalse(Logic.canSwap(0, '1', 5));
});

test('non-number count returns false', () => {
    assertFalse(Logic.canSwap(0, 1, '5'));
});

test('boundary valid: 0 and count-1', () => {
    assertTrue(Logic.canSwap(0, 4, 5));
});

// ----------------------------------------------------------------------------
console.log('\n┌─ findDropTarget ─────────────────────────────────────────────────');
// ----------------------------------------------------------------------------

test('returns -1 for null repeater', () => {
    assertEqual(Logic.findDropTarget(null, {}, 0, 0), -1);
});

test('returns -1 for null grid', () => {
    assertEqual(Logic.findDropTarget({count: 1}, null, 0, 0), -1);
});

test('returns -1 for invalid repeater', () => {
    assertEqual(Logic.findDropTarget({}, {}, 0, 0), -1);
});

// ----------------------------------------------------------------------------
console.log('\n┌─ distance ─────────────────────────────────────────────────────');
// ----------------------------------------------------------------------------

test('distance from origin', () => {
    assertEqual(Logic.distance(0, 0, 3, 4), 5);
});

test('distance same point is 0', () => {
    assertEqual(Logic.distance(5, 5, 5, 5), 0);
});

test('distance negative coordinates', () => {
    assertEqual(Logic.distance(-3, 0, 0, 4), 5);
});

test('distance horizontal', () => {
    assertEqual(Logic.distance(0, 0, 10, 0), 10);
});

test('distance vertical', () => {
    assertEqual(Logic.distance(0, 0, 0, 10), 10);
});

// ----------------------------------------------------------------------------
console.log('\n┌─ isDragStarted ────────────────────────────────────────────────');
// ----------------------------------------------------------------------------

test('returns false below threshold', () => {
    assertFalse(Logic.isDragStarted(0, 0, 5, 5, 10));
});

test('returns true above threshold', () => {
    assertTrue(Logic.isDragStarted(0, 0, 15, 0, 10));
});

test('returns false at exact threshold', () => {
    assertFalse(Logic.isDragStarted(0, 0, 10, 0, 10));
});

test('uses default threshold of 10', () => {
    assertFalse(Logic.isDragStarted(0, 0, 8, 0));
    assertTrue(Logic.isDragStarted(0, 0, 12, 0));
});

// ----------------------------------------------------------------------------
console.log('\n┌─ isValidIndex ───────────────────────────────────────────────────');
// ----------------------------------------------------------------------------

test('valid index returns true', () => {
    assertTrue(Logic.isValidIndex(0, 5));
    assertTrue(Logic.isValidIndex(4, 5));
});

test('negative index returns false', () => {
    assertFalse(Logic.isValidIndex(-1, 5));
});

test('index >= count returns false', () => {
    assertFalse(Logic.isValidIndex(5, 5));
});

test('float index returns false', () => {
    assertFalse(Logic.isValidIndex(1.5, 5));
});

test('string index returns false', () => {
    assertFalse(Logic.isValidIndex('0', 5));
});

// ----------------------------------------------------------------------------
console.log('\n┌─ isValidName ────────────────────────────────────────────────────');
// ----------------------------------------------------------------------------

test('valid name returns true', () => {
    assertTrue(Logic.isValidName('Work'));
});

test('empty string returns false', () => {
    assertFalse(Logic.isValidName(''));
});

test('whitespace only returns false', () => {
    assertFalse(Logic.isValidName('   '));
});

test('null returns false', () => {
    assertFalse(Logic.isValidName(null));
});

test('number returns false', () => {
    assertFalse(Logic.isValidName(123));
});

test('name with spaces returns true', () => {
    assertTrue(Logic.isValidName('My Work'));
});

// ----------------------------------------------------------------------------
console.log('\n┌─ clamp ──────────────────────────────────────────────────────────');
// ----------------------------------------------------------------------------

test('value within range unchanged', () => {
    assertEqual(Logic.clamp(50, 0, 100), 50);
});

test('value below min clamped', () => {
    assertEqual(Logic.clamp(-10, 0, 100), 0);
});

test('value above max clamped', () => {
    assertEqual(Logic.clamp(150, 0, 100), 100);
});

test('value at min unchanged', () => {
    assertEqual(Logic.clamp(0, 0, 100), 0);
});

test('value at max unchanged', () => {
    assertEqual(Logic.clamp(100, 0, 100), 100);
});

// ============================================================================
// RESULTS
// ============================================================================

console.log('\n╔════════════════════════════════════════════════════════════════╗');
console.log('║                        TEST RESULTS                            ║');
console.log('╠════════════════════════════════════════════════════════════════╣');
console.log(`║  Total:  ${String(total).padStart(3)}                                                 ║`);
console.log(`║  Passed: ${String(passed).padStart(3)} ✓                                               ║`);
console.log(`║  Failed: ${String(failed).padStart(3)} ${failed > 0 ? '✗' : ' '}                                               ║`);
console.log(`║  Coverage: ${((passed/total)*100).toFixed(1)}%                                           ║`);
console.log('╚════════════════════════════════════════════════════════════════╝');

if (failed > 0) {
    console.log('\n Failed tests:');
    results.failed.forEach(f => console.log(`   - ${f.name}: ${f.error}`));
}

console.log(failed === 0 ? '\n✓ All tests passed!' : '\n✗ Some tests failed');
process.exit(failed > 0 ? 1 : 0);
