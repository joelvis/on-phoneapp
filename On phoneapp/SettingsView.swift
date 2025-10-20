//
//  SettingsView.swift
//  On phoneapp
//
//  Created by Joel  on 10/18/25.
//

import SwiftUI
import UserNotifications

struct SettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("taskSoundEnabled") private var taskSoundEnabled = true
    @AppStorage("defaultTaskPriority") private var defaultTaskPriority = 1
    @AppStorage("showCompletedTasks") private var showCompletedTasks = true
    @AppStorage("defaultReminderMinutes") private var defaultReminderMinutes = 60
    @AppStorage("themePreference") private var themePreference = "system"
    @AppStorage("autoDeleteCompletedTasks") private var autoDeleteCompletedTasks = false
    @AppStorage("deleteAfterDays") private var deleteAfterDays = 7

    @State private var notificationStatus = "Unknown"
    @State private var showingDeleteConfirmation = false
    @State private var showingResetConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Adaptive background
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()

                Form {
                    // MARK: - Notifications Section
                    Section {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.orange)
                            Text("Notification Status")
                            Spacer()
                            Text(notificationStatus)
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        }

                        Toggle(isOn: $notificationsEnabled) {
                            Label("Enable Notifications", systemImage: "bell.badge")
                        }
                        .onChange(of: notificationsEnabled) { _, newValue in
                            if newValue {
                                requestNotificationPermission()
                            }
                        }

                        Toggle(isOn: $taskSoundEnabled) {
                            Label("Notification Sound", systemImage: "speaker.wave.2")
                        }
                        .disabled(!notificationsEnabled)

                        Picker("Default Reminder Time", selection: $defaultReminderMinutes) {
                            Text("15 minutes before").tag(15)
                            Text("30 minutes before").tag(30)
                            Text("1 hour before").tag(60)
                            Text("2 hours before").tag(120)
                            Text("1 day before").tag(1440)
                        }
                        .disabled(!notificationsEnabled)

                        Button(action: {
                            openNotificationSettings()
                        }) {
                            HStack {
                                Text("Open Notification Settings")
                                Spacer()
                                Image(systemName: "arrow.up.forward.app")
                                    .font(.caption)
                            }
                        }
                    } header: {
                        Text("Notifications")
                    } footer: {
                        Text("Manage how you receive task reminders and notifications.")
                    }

                    // MARK: - Task Settings Section
                    Section {
                        Picker("Default Priority", selection: $defaultTaskPriority) {
                            Label("Low", systemImage: "flag.fill")
                                .foregroundColor(.green)
                                .tag(0)
                            Label("Medium", systemImage: "flag.fill")
                                .foregroundColor(.orange)
                                .tag(1)
                            Label("High", systemImage: "flag.fill")
                                .foregroundColor(.red)
                                .tag(2)
                        }

                        Toggle(isOn: $showCompletedTasks) {
                            Label("Show Completed Tasks", systemImage: "checkmark.circle")
                        }

                        Toggle(isOn: $autoDeleteCompletedTasks) {
                            Label("Auto-Delete Completed Tasks", systemImage: "trash")
                        }

                        if autoDeleteCompletedTasks {
                            Stepper("Delete after \(deleteAfterDays) day\(deleteAfterDays == 1 ? "" : "s")", value: $deleteAfterDays, in: 1...30)
                        }
                    } header: {
                        Text("Task Settings")
                    } footer: {
                        Text("Customize default task behavior and display preferences.")
                    }

                    // MARK: - Appearance Section
                    Section {
                        Picker("Theme", selection: $themePreference) {
                            Label("System", systemImage: "iphone")
                                .tag("system")
                            Label("Light", systemImage: "sun.max")
                                .tag("light")
                            Label("Dark", systemImage: "moon")
                                .tag("dark")
                        }
                        .pickerStyle(.segmented)
                    } header: {
                        Text("Appearance")
                    } footer: {
                        Text("Note: Theme preference requires app restart to take effect.")
                    }

                    // MARK: - Data Management Section
                    Section {
                        Button(action: {
                            showingDeleteConfirmation = true
                        }) {
                            HStack {
                                Label("Delete All Completed Tasks", systemImage: "trash.fill")
                                    .foregroundColor(.orange)
                                Spacer()
                            }
                        }

                        Button(action: {
                            exportData()
                        }) {
                            HStack {
                                Label("Export All Data", systemImage: "square.and.arrow.up")
                                Spacer()
                            }
                        }

                        Button(action: {
                            showingResetConfirmation = true
                        }) {
                            HStack {
                                Label("Reset All Settings", systemImage: "arrow.counterclockwise")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }
                    } header: {
                        Text("Data Management")
                    } footer: {
                        Text("Manage your app data and settings.")
                    }

                    // MARK: - About Section
                    Section {
                        HStack {
                            Text("App Version")
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Build Number")
                            Spacer()
                            Text("1")
                                .foregroundColor(.secondary)
                        }

                        Link(destination: URL(string: "https://example.com/privacy")!) {
                            HStack {
                                Text("Privacy Policy")
                                Spacer()
                                Image(systemName: "arrow.up.forward")
                                    .font(.caption)
                            }
                        }

                        Link(destination: URL(string: "https://example.com/terms")!) {
                            HStack {
                                Text("Terms of Service")
                                Spacer()
                                Image(systemName: "arrow.up.forward")
                                    .font(.caption)
                            }
                        }
                    } header: {
                        Text("About")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                checkNotificationStatus()
            }
            .alert("Delete Completed Tasks", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAllCompletedTasks()
                }
            } message: {
                Text("Are you sure you want to delete all completed tasks? This action cannot be undone.")
            }
            .alert("Reset All Settings", isPresented: $showingResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetAllSettings()
                }
            } message: {
                Text("Are you sure you want to reset all settings to their default values? This will not delete your tasks or notes.")
            }
        }
    }

    // MARK: - Helper Functions

    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized:
                    notificationStatus = "Enabled"
                case .denied:
                    notificationStatus = "Disabled"
                case .notDetermined:
                    notificationStatus = "Not Set"
                case .provisional:
                    notificationStatus = "Provisional"
                case .ephemeral:
                    notificationStatus = "Ephemeral"
                @unknown default:
                    notificationStatus = "Unknown"
                }
            }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    notificationStatus = "Enabled"
                    print("✅ Notification permission granted")
                } else {
                    notificationStatus = "Disabled"
                    notificationsEnabled = false
                    print("⚠️ Notification permission denied")
                }
            }
        }
    }

    private func openNotificationSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func deleteAllCompletedTasks() {
        // Load tasks
        let tasksKey = "saved_tasks"
        guard let data = UserDefaults.standard.data(forKey: tasksKey),
              var tasks = try? JSONDecoder().decode([Task].self, from: data) else {
            return
        }

        // Remove completed tasks
        let beforeCount = tasks.count
        tasks.removeAll { $0.isCompleted }
        let deletedCount = beforeCount - tasks.count

        // Save updated tasks
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: tasksKey)
            print("✅ Deleted \(deletedCount) completed tasks")
        }
    }

    private func exportData() {
        // This would implement data export functionality
        // For now, just a placeholder that could generate a JSON file
        print("📤 Export data functionality - to be implemented")

        // Future implementation could:
        // 1. Gather all tasks and notes
        // 2. Create a JSON file
        // 3. Present share sheet to export
    }

    private func resetAllSettings() {
        notificationsEnabled = true
        taskSoundEnabled = true
        defaultTaskPriority = 1
        showCompletedTasks = true
        defaultReminderMinutes = 60
        themePreference = "system"
        autoDeleteCompletedTasks = false
        deleteAfterDays = 7

        print("✅ All settings reset to defaults")
    }
}

#Preview {
    SettingsView()
}
