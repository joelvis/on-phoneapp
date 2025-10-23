//
//  ToolboxApp.swift
//  Toolbox
//
//  Created by Joel  on 10/17/25.
//

import SwiftUI
import UserNotifications

@main
struct ToolboxApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // Initialize Core Data on app launch
    init() {
        print("🚀 ToolboxApp: Initializing Core Data...")

        // Initialize persistent container (lazy property will load it)
        _ = CoreDataManager.shared.persistentContainer

        // Migrate data from UserDefaults to Core Data (runs once)
        CoreDataManager.shared.migrateDataFromUserDefaults()

        print("✅ ToolboxApp: Core Data initialization complete")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - App Delegate for Notifications
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Set the notification delegate
        UNUserNotificationCenter.current().delegate = self

        // Request notification authorization on app launch
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification permission granted on launch")
            } else {
                print("⚠️ Notification permission denied")
            }
            if let error = error {
                print("❌ Error requesting notification permission: \(error)")
            }
        }

        return true
    }

    // This method is called when a notification is delivered while the app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("📬 Notification will present: \(notification.request.content.body)")
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    // This method is called when the user interacts with a notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("👆 User tapped notification: \(response.notification.request.content.body)")
        completionHandler()
    }
}
