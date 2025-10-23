#!/bin/bash

# Clean and Open Xcode Project Script
# This script cleans all Xcode caches and opens your project fresh

set -e  # Exit on error

echo "🧹 Cleaning Xcode caches and project data..."
echo ""

# Close Xcode if running
echo "1️⃣ Closing Xcode..."
killall Xcode 2>/dev/null && echo "   ✓ Xcode closed" || echo "   ✓ Xcode was not running"
sleep 2

# Clean Xcode's Derived Data
echo "2️⃣ Cleaning Derived Data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*
echo "   ✓ Derived Data cleaned"

# Navigate to project directory
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

# Clean project-specific cache files
echo "3️⃣ Cleaning project caches..."
rm -rf "On phoneapp.xcodeproj/xcuserdata"
rm -rf "On phoneapp.xcodeproj/project.xcworkspace/xcuserdata"
echo "   ✓ Project caches cleaned"

echo ""
echo "✅ Cleaning complete!"
echo ""
echo "🚀 Opening project in Xcode..."
sleep 1

# Open the project
open "On phoneapp.xcodeproj"

echo ""
echo "📝 Next steps in Xcode:"
echo "   1. Wait for Xcode to fully load"
echo "   2. Select a simulator (iPhone 15 or similar)"
echo "   3. Press Shift+Cmd+K to Clean Build Folder"
echo "   4. Press Cmd+B to Build"
echo "   5. Press Cmd+R to Run"
echo ""
echo "If Xcode still crashes, check XCODE_CRASH_FIX.md for more help."

