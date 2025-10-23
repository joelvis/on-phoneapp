# On Phone App

**A comprehensive iOS/macOS productivity toolkit built with SwiftUI**

[![Xcode](https://img.shields.io/badge/Xcode-26.0.1-blue.svg)](https://developer.apple.com/xcode/)
[![Swift](https://img.shields.io/badge/Swift-5.0+-orange.svg)](https://swift.org/)
[![Platform](https://img.shields.io/badge/Platform-iOS%2026%20|%20macOS%2026%20|%20visionOS%2026-lightgrey.svg)](https://developer.apple.com/)

---

## ⚠️ Important Note

**This project requires Xcode 26.0.1 or later** (currently in beta/preview). It will not build with earlier versions of Xcode.

---

## Features

### 📝 Notes
- Create, edit, and organize notes
- Rich text support
- Core Data persistence
- Search functionality

### ✅ Tasks
- Task management with priorities (Low, Medium, High)
- Due dates and reminders
- Categories and filtering
- Local notifications
- Core Data persistence

### 🔐 Vault
- Secure document storage with encryption
- Biometric authentication (Face ID/Touch ID)
- PIN code backup authentication
- Document scanning
- Photo encryption with per-file keys
- OCR text extraction for searchability
- Core Data persistence

### ⚙️ Settings
- Notification preferences
- Task defaults
- Theme selection
- Data management

---

## Requirements

- **Xcode:** 26.0.1 or later
- **macOS:** Latest version with Xcode support
- **Deployment:** iOS 26.0+, macOS 26.0+, visionOS 26.0+

---

## Getting Started

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/On-phoneapp.git
cd "On phoneapp"
```

2. Open the project:
```bash
open "On phoneapp.xcodeproj"
```

3. Select your target device/simulator

4. Build and run (Cmd + R)

### First Build

If you encounter issues on first build:
```bash
./clean_and_open.sh
```

Or manually clean:
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```

---

## Project Structure

```
On phoneapp/
├── On phoneapp/
│   ├── On_phoneappApp.swift          # Main app entry point
│   ├── ContentView.swift             # Tab bar navigation
│   ├── HomeView.swift                # Home screen
│   ├── NotesAppView.swift            # Notes feature
│   ├── TaskManagerView.swift         # Task manager
│   ├── VaultView.swift               # Secure vault
│   ├── SettingsView.swift            # Settings
│   ├── CoreDataManager.swift         # Core Data stack
│   └── CoreDataExtensions.swift      # Entity extensions
├── ToolboxDataModel.xcdatamodeld/   # Core Data model
└── README.md                         # This file
```

### Technologies

- **SwiftUI** - Modern, declarative UI
- **Core Data** - Local persistence
- **LocalAuthentication** - Biometric security
- **VisionKit** - Document scanning
- **CryptoKit** - Encryption
- **UserNotifications** - Task reminders

---

## Documentation

- [`PROJECT_STATUS.md`](PROJECT_STATUS.md) - Current project status and configuration
- [`XCODE_CRASH_FIX.md`](XCODE_CRASH_FIX.md) - Troubleshooting guide
- [`CORE_DATA_SETUP.md`](CORE_DATA_SETUP.md) - Core Data configuration
- [`VAULT_SETUP.md`](VAULT_SETUP.md) - Vault security implementation

---

## Recent Updates

**October 23, 2025:**
- ✅ Fixed Xcode 26 compatibility issues
- ✅ Updated Core Data code generation
- ✅ Resolved build errors
- ✅ Added comprehensive documentation
- ✅ Project builds successfully

See [`PROJECT_STATUS.md`](PROJECT_STATUS.md) for detailed technical information.

---

## Building the Project

### Quick Start
```bash
# Open the project
open "On phoneapp.xcodeproj"

# In Xcode:
# 1. Select simulator/device
# 2. Press Cmd + B to build
# 3. Press Cmd + R to run
```

### Troubleshooting

If Xcode crashes:
```bash
./clean_and_open.sh
```

If build fails:
1. Clean Build Folder (Shift + Cmd + K)
2. Rebuild (Cmd + B)

---

## Core Data Model

The app uses Core Data for persistence with three main entities:

- **NoteEntity** - Notes storage
- **TaskEntity** - Task management
- **VaultItemEntity** - Secure document storage

Code generation is automatic with custom extensions in `CoreDataExtensions.swift`.

---

## Security

### Vault Features:
- AES-256 encryption with per-file keys
- Keys stored in iOS Keychain
- Biometric authentication (Face ID/Touch ID)
- PIN code fallback
- File protection (`.complete` level)

---

## Contributing

This is a personal project, but suggestions and feedback are welcome!

---

## License

[Add your license here]

---

## Author

Joel

---

**Built with ❤️ using SwiftUI and Core Data**
