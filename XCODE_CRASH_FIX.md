# Xcode Crash Troubleshooting Guide

## Issues Fixed

### 1. ✅ Deployment Target Configuration (CRITICAL)
**Problem:** Deployment targets were set to non-existent versions:
- iOS: 26.0 (doesn't exist - current is ~18.x)
- macOS: 26.0 (doesn't exist - current is ~15.x)
- visionOS: 26.0 (doesn't exist - current is ~2.x)

**Fixed to:**
- iOS: 17.0 ✓
- macOS: 14.0 ✓
- visionOS: 2.0 ✓

### 2. ✅ App Struct Naming Mismatch
**Problem:** Main app struct was named `ToolboxApp` instead of `On_phoneappApp`
**Fixed:** Renamed to match project and module name

## How to Open Your Project Now

### Step 1: Clean Xcode Cache (IMPORTANT)

Open Terminal and run these commands:

```bash
# Navigate to your project
cd "/Users/joel/Downloads/On phoneapp"

# Clean Xcode's derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Clean project-specific cache
rm -rf "On phoneapp.xcodeproj/xcuserdata"
rm -rf "On phoneapp.xcodeproj/project.xcworkspace/xcuserdata"

# Make sure Xcode is completely closed
killall Xcode 2>/dev/null || true

echo "✅ Cleaning complete!"
```

### Step 2: Open the Project

```bash
# Open the project file directly
open "On phoneapp.xcodeproj"
```

OR manually:
1. Open Xcode
2. File → Open
3. Navigate to `/Users/joel/Downloads/On phoneapp/`
4. Select `On phoneapp.xcodeproj`

### Step 3: First Build

Once Xcode opens:
1. Select a simulator (iPhone 15 or similar)
2. Product → Clean Build Folder (Shift + Cmd + K)
3. Product → Build (Cmd + B)

## If It Still Crashes

### What Information to Collect:

1. **Crash Logs:**
   ```bash
   # View recent crash logs
   ls -lt ~/Library/Logs/DiagnosticReports/Xcode*.crash | head -5
   
   # Copy the most recent one
   cat ~/Library/Logs/DiagnosticReports/Xcode_*.crash | pbcopy
   ```
   Then paste the crash log for analysis.

2. **Xcode Console Output:**
   - Open Xcode from Terminal: `open -a Xcode "On phoneapp.xcodeproj"`
   - The Terminal will show any error messages
   - Copy and share those messages

3. **System Info:**
   ```bash
   sw_vers
   xcodebuild -version
   ```

4. **Project Validation:**
   ```bash
   cd "/Users/joel/Downloads/On phoneapp"
   xcodebuild -list -project "On phoneapp.xcodeproj"
   ```

### Alternative: Create a Fresh Project

If Xcode still crashes, the project file may be corrupted. You can:

1. Create a new Xcode project with the same name
2. Copy all `.swift` files from `On phoneapp/` folder
3. Copy `Assets.xcassets` and `.xcdatamodeld` folders
4. Rebuild the project structure

## Expected Xcode Version

This project uses:
- **Xcode 16.0+** (based on the `objectVersion = 77` in project file)
- Swift 5.0+

Check your Xcode version:
```bash
xcodebuild -version
```

If you're using an older Xcode version, you may need to:
1. Update Xcode from the Mac App Store
2. OR downgrade the project's `objectVersion` in `project.pbxproj`

## Why This Happened

The deployment target issue likely occurred because:
1. Someone manually edited the project file with incorrect values
2. A beta/preview version of Xcode set future version numbers
3. A script or tool misconfigured the project settings

The app naming issue happened because the project was likely:
1. Renamed from "Toolbox" to "On phoneapp" 
2. But the internal struct name wasn't updated

## Current Project Configuration

- **Product Name:** On phoneapp
- **Bundle ID:** joel-test.On-phoneapp
- **Display Name:** Joel's App
- **Deployment Targets:**
  - iOS 17.0+
  - macOS 14.0+
  - visionOS 2.0+
- **Module Name:** On_phoneapp
- **Main App Struct:** On_phoneappApp

## Testing Checklist

After opening:
- [ ] Project opens without crashing
- [ ] Can select a simulator
- [ ] Clean build succeeds
- [ ] Build succeeds
- [ ] App runs on simulator
- [ ] All tabs work (Home, Notes, Tasks, Vault, Settings)
- [ ] Core Data initializes properly

