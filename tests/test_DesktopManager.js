#!/usr/bin/env node
// Test suite for DesktopManager.js
// Run with: node test_DesktopManager.js

// Load the module (remove QML-specific pragma)
const fs = require('fs');
const path = require('path');
const srcPath = path.join(__dirname, '../contents/ui/DesktopManager.js');
let code = fs.readFileSync(srcPath, 'utf8');
code = code.replace('.pragma library', '');
code += '\nmodule.exports = { buildRemoveCommand, buildRenameCommand, buildCreateCommand, buildSwapWindowsCommand, escapeShell, calculateGrid, calculatePreviewSize, calculateScale, canSwap, nextDesktop };';
fs.writeFileSync('/tmp/DM_test.js', code);
const DM = require('/tmp/DM_test.js');

let passed = 0;
let failed = 0;

function test(name, condition) {
    if (condition) {
        console.log(`✓ ${name}`);
        passed++;
    } else {
        console.log(`✗ ${name}`);
        failed++;
    }
}

function testEqual(name, actual, expected) {
    if (actual === expected) {
        console.log(`✓ ${name}`);
        passed++;
    } else {
        console.log(`✗ ${name}: expected "${expected}", got "${actual}"`);
        failed++;
    }
}

console.log('\n=== Testing DesktopManager.js ===\n');

// Test buildRemoveCommand
console.log('--- buildRemoveCommand ---');
testEqual('Remove with valid ID',
    DM.buildRemoveCommand('abc-123'),
    "qdbus org.kde.KWin /VirtualDesktopManager removeDesktop 'abc-123'"
);
test('Remove with null ID returns null', DM.buildRemoveCommand(null) === null);
test('Remove with empty ID returns null', DM.buildRemoveCommand('') === null);

// Test buildRenameCommand
console.log('\n--- buildRenameCommand ---');
testEqual('Rename simple',
    DM.buildRenameCommand('id1', 'Work'),
    "qdbus org.kde.KWin /VirtualDesktopManager setDesktopName 'id1' 'Work'"
);
test('Rename with null ID returns null', DM.buildRenameCommand(null, 'name') === null);
test('Rename with empty name returns null', DM.buildRenameCommand('id', '') === null);
test('Rename with whitespace name returns null', DM.buildRenameCommand('id', '   ') === null);

// Test escapeShell
console.log('\n--- escapeShell ---');
testEqual('Escape single quote', DM.escapeShell("it's"), "it'\\''s");
testEqual('No escape needed', DM.escapeShell("hello"), "hello");

// Test buildCreateCommand
console.log('\n--- buildCreateCommand ---');
testEqual('Create at position 5',
    DM.buildCreateCommand(5, 'New Desktop'),
    "qdbus org.kde.KWin /VirtualDesktopManager createDesktop 5 'New Desktop'"
);

// Test buildSwapWindowsCommand
console.log('\n--- buildSwapWindowsCommand ---');
test('Swap command contains wmctrl',
    DM.buildSwapWindowsCommand(0, 1).includes('wmctrl')
);
test('Swap command contains both indices',
    DM.buildSwapWindowsCommand(2, 5).includes('2') && DM.buildSwapWindowsCommand(2, 5).includes('5')
);

// Test calculateGrid
console.log('\n--- calculateGrid ---');
let grid1 = DM.calculateGrid(1);
testEqual('Grid for 1: cols', grid1.cols, 1);
testEqual('Grid for 1: rows', grid1.rows, 1);

let grid4 = DM.calculateGrid(4);
testEqual('Grid for 4: cols', grid4.cols, 2);
testEqual('Grid for 4: rows', grid4.rows, 2);

let grid5 = DM.calculateGrid(5);
testEqual('Grid for 5: cols', grid5.cols, 3);
testEqual('Grid for 5: rows', grid5.rows, 2);

let grid9 = DM.calculateGrid(9);
testEqual('Grid for 9: cols', grid9.cols, 3);
testEqual('Grid for 9: rows', grid9.rows, 3);

// Test calculatePreviewSize
console.log('\n--- calculatePreviewSize ---');
let preview = DM.calculatePreviewSize(130, 1920, 1080);
testEqual('Preview width', preview.width, 130);
test('Preview height is proportional', Math.abs(preview.height - 73.125) < 0.01);

// Test calculateScale
console.log('\n--- calculateScale ---');
let scale = DM.calculateScale(130, 73, 1920, 1080);
test('Scale X is positive', scale.x > 0);
test('Scale Y is positive', scale.y > 0);

// Test canSwap
console.log('\n--- canSwap ---');
test('canSwap valid', DM.canSwap(0, 1, 5) === true);
test('canSwap same index', DM.canSwap(2, 2, 5) === false);
test('canSwap negative A', DM.canSwap(-1, 1, 5) === false);
test('canSwap negative B', DM.canSwap(0, -1, 5) === false);
test('canSwap A out of bounds', DM.canSwap(5, 1, 5) === false);
test('canSwap B out of bounds', DM.canSwap(0, 5, 5) === false);

// Test nextDesktop
console.log('\n--- nextDesktop ---');
testEqual('Next from 0 (forward)', DM.nextDesktop(0, 5, 1), 1);
testEqual('Next from 4 (forward, wrap)', DM.nextDesktop(4, 5, 1), 0);
testEqual('Next from 0 (backward, wrap)', DM.nextDesktop(0, 5, -1), 4);
testEqual('Next from 2 (backward)', DM.nextDesktop(2, 5, -1), 1);

// Summary
console.log('\n=== Results ===');
console.log(`Passed: ${passed}`);
console.log(`Failed: ${failed}`);
console.log(failed === 0 ? '\n✓ All tests passed!' : '\n✗ Some tests failed');

process.exit(failed > 0 ? 1 : 0);
