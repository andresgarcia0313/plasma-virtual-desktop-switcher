#!/bin/bash
# Run all tests for Virtual Desktop Switcher
cd "$(dirname "$0")"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║      Virtual Desktop Switcher - Test Suite                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

FAILED=0

echo "▶ Running test_DesktopLogic.js..."
if node test_DesktopLogic.js; then
    echo ""
else
    FAILED=1
fi

echo ""
echo "▶ Running test_DesktopManager.js..."
if node test_DesktopManager.js; then
    echo ""
else
    FAILED=1
fi

echo ""
if [ $FAILED -eq 0 ]; then
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  ✓ ALL TESTS PASSED                                          ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    exit 0
else
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  ✗ SOME TESTS FAILED                                         ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    exit 1
fi
