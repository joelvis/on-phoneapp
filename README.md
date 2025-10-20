# Joel's App

A modern, modular iOS app built with SwiftUI featuring a home screen and tab-based mini-app architecture.

## Features

### Architecture
- **Home Screen**: Welcoming home screen with time display and quick access to all apps
- **Modular Design**: Each mini-app is a self-contained view that can be easily extended
- **Tab-Based Navigation**: Clean bottom tab bar with 5 tabs (Home + 4 mini-apps)
- **Extensible**: Easy to add new mini-apps by creating new views and adding them to the TabView

### Tabs

#### 1. Home (Main Screen)
- Welcome message and live clock
- Beautiful gradient background
- Quick access cards to all mini-apps
- Real-time date and time display

#### 2. Notes App (Fully Functional)
- Create, view, and delete notes
- Clean card-based UI
- Persistent storage using @AppStorage
- Beautiful empty state
- Vintage Apple-style X button for dismissing views

#### 3-5. Placeholder Apps
- Ready-to-implement blank canvases
- Each has its own dedicated view
- Simply replace the placeholder content with your desired functionality

## How to Build

1. Open `On phoneapp.xcodeproj` in Xcode
2. Select your target device (simulator or physical device)
3. Press Cmd+R to build and run

## Project Structure

```
On phoneapp/
├── ContentView.swift           # Main tab view container
├── HomeView.swift              # Home screen with welcome and quick access
├── NotesAppView.swift          # Full-featured notes app
├── PlaceholderAppView.swift    # Template for new mini-apps
└── On_phoneappApp.swift        # App entry point
```

## Adding New Mini Apps

To add a new mini-app:

1. Create a new SwiftUI View file (e.g., `MyNewAppView.swift`)
2. Design your app's functionality
3. Add it to the TabView in `ContentView.swift`:

```swift
MiniAppContainer {
    MyNewAppView()
}
.tabItem {
    Image(systemName: "your.icon.name")
    Text("My App")
}
.tag(4) // Increment the tag number
```

## Design Philosophy

- **Apple-Style UI**: Uses native iOS components and design patterns
- **Modern & Clean**: Follows iOS design guidelines
- **Full-Screen Mini Apps**: Each app takes up the entire screen
- **Consistent Navigation**: All views use vintage Apple-style X buttons for dismissal
- **Persistent Data**: Notes are saved automatically using @AppStorage

## Technologies

- SwiftUI
- iOS 17+
- @AppStorage for data persistence
- NavigationStack for navigation
- SF Symbols for icons

## Notes App Features

- ✅ Create notes with title and content
- ✅ View note details in full screen
- ✅ Delete notes with X button
- ✅ Automatic date tracking
- ✅ Beautiful empty state
- ✅ Persistent storage (survives app restarts)
- ✅ Card-based layout

## Future Enhancements

You can easily replace the placeholder apps (App 2, App 3, App 4) with:
- Calculator
- Todo List
- Voice Recorder
- Photo Gallery
- Weather App
- Timer/Stopwatch
- Or any other functionality you need!

