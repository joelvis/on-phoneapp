//
//  ContentView.swift
//  On phoneapp
//
//  Created by Joel  on 10/17/25.
//

import SwiftUI

struct ContentView: View {
    init() {
        // Configure tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()

        // Set gray background color
        appearance.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)

        // Add shadow to tab bar icons
        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = UIColor.systemGray
        itemAppearance.selected.iconColor = UIColor.systemBlue

        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance

        // Enable shadow
        UITabBar.appearance().layer.shadowColor = UIColor.black.cgColor
        UITabBar.appearance().layer.shadowOffset = CGSize(width: 0, height: -2)
        UITabBar.appearance().layer.shadowRadius = 4
        UITabBar.appearance().layer.shadowOpacity = 0.15
    }

    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            NotesAppView()
                .tabItem {
                    Label("Notes", systemImage: "note.text")
                }
                .tag(1)

            TaskManagerView()
                .tabItem {
                    Label("Tasks", systemImage: "checklist")
                }
                .tag(2)

            VaultView()
                .tabItem {
                    Label("Vault", systemImage: "lock.shield.fill")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(4)
        }
    }
}

#Preview {
    ContentView()
}
