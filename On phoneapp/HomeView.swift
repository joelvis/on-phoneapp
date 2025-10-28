//
//  HomeView.swift
//  On phoneapp
//
//  Redesigned to match Figma design exactly
//

import SwiftUI
import Combine
import CoreData

// MARK: - Data Counter
class DataCounter: ObservableObject {
    static let shared = DataCounter()
    
    @Published var vaultCount = 0
    @Published var notesCount = 0
    @Published var tasksCount = 0
    @Published var totalItems = 0
    
    private let context = CoreDataManager.shared.viewContext
    
    func refreshCounts() {
        // Fetch Vault items count
        let vaultRequest: NSFetchRequest<VaultItemEntity> = NSFetchRequest(entityName: "VaultItemEntity")
        vaultCount = (try? context.count(for: vaultRequest)) ?? 0
        
        // Fetch Notes count
        let notesRequest: NSFetchRequest<NoteEntity> = NSFetchRequest(entityName: "NoteEntity")
        notesCount = (try? context.count(for: notesRequest)) ?? 0
        
        // Fetch Tasks count
        let tasksRequest: NSFetchRequest<TaskEntity> = NSFetchRequest(entityName: "TaskEntity")
        tasksCount = (try? context.count(for: tasksRequest)) ?? 0
        
        // Calculate total
        totalItems = vaultCount + notesCount + tasksCount
        
        print("📊 DataCounter: Vault: \(vaultCount), Notes: \(notesCount), Tasks: \(tasksCount), Total: \(totalItems)")
    }
}

struct HomeView: View {
    @Binding var selectedTab: Int
    @State private var showContent = false
    @StateObject private var dataCounter = DataCounter.shared
    
    init(selectedTab: Binding<Int>) {
        self._selectedTab = selectedTab
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Header Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome back")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : -10)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: showContent)
                    
                    Text("Toolbox")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : -10)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: showContent)
                    
                    Text("All your essentials in one place")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.5))
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : -10)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: showContent)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 24)
                
                // Stats Card
                StatsCard(totalItems: dataCounter.totalItems)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: showContent)
                
                // Main Feature Cards
                VStack(spacing: 16) {
                    FeatureCard(
                        icon: "lock.fill",
                        title: "Vault",
                        subtitle: "Secure documents",
                        count: dataCounter.vaultCount,
                        accentColor: Color(red: 0.3, green: 0.5, blue: 1.0),
                        iconBackground: Color(red: 0.15, green: 0.2, blue: 0.35)
                    )
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: showContent)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = 3
                        }
                    }
                    
                    FeatureCard(
                        icon: "doc.text.fill",
                        title: "Notes",
                        subtitle: "Quick thoughts",
                        count: dataCounter.notesCount,
                        accentColor: Color(red: 0.6, green: 0.4, blue: 1.0),
                        iconBackground: Color(red: 0.25, green: 0.15, blue: 0.35)
                    )
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: showContent)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = 1
                        }
                    }
                    
                    FeatureCard(
                        icon: "checkmark.square.fill",
                        title: "Tasks",
                        subtitle: "Stay organized",
                        count: dataCounter.tasksCount,
                        accentColor: Color(red: 1.0, green: 0.6, blue: 0.2),
                        iconBackground: Color(red: 0.3, green: 0.2, blue: 0.15)
                    )
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.7), value: showContent)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = 2
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                
                // Quick Actions Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Quick Actions")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 24)
                        .opacity(showContent ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.8), value: showContent)
                    
                    HStack(spacing: 16) {
                        QuickActionButton(
                            icon: "plus",
                            title: "New Note",
                            action: {
                                selectedTab = 1
                            }
                        )
                        
                        QuickActionButton(
                            icon: "plus",
                            title: "New Task",
                            action: {
                                selectedTab = 2
                            }
                        )
                        
                        QuickActionButton(
                            icon: "plus",
                            title: "Scan\nDocument",
                            action: {
                                selectedTab = 3
                            }
                        )
                    }
                    .padding(.horizontal, 24)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.9), value: showContent)
                }
                .padding(.bottom, 40)
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.08),
                    Color(red: 0.08, green: 0.08, blue: 0.12)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .onAppear {
            // Refresh data counts
            dataCounter.refreshCounts()
            
            // Trigger animations
            withAnimation {
                showContent = true
            }
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            // Refresh counts when returning to home tab
            if newValue == 0 {
                dataCounter.refreshCounts()
            }
        }
    }
}

// MARK: - Stats Card
struct StatsCard: View {
    let totalItems: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(totalItems)")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Total Items")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                        
                        Text("Encrypted")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.green)
                    }
                    
                    Text("Secure on device")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            // Gradient Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    
                    // Gradient fill (65% progress)
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.3, green: 0.5, blue: 1.0),
                            Color(red: 0.6, green: 0.4, blue: 1.0),
                            Color(red: 1.0, green: 0.5, blue: 0.3)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .mask(
                        RoundedRectangle(cornerRadius: 4)
                            .frame(width: geometry.size.width * 0.65, height: 8)
                    )
                }
            }
            .frame(height: 8)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.16))
        )
    }
}

// MARK: - Feature Card
struct FeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let count: Int
    let accentColor: Color
    let iconBackground: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon container
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(iconBackground)
                    .frame(width: 64, height: 64)
                
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(accentColor)
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                    
                    // Count badge
                    Text("\(count)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(accentColor.opacity(0.2))
                        )
                }
                
                Text(subtitle)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.16))
        )
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 0.15, green: 0.15, blue: 0.2))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.1, green: 0.1, blue: 0.14))
            )
        }
    }
}

#Preview {
    HomeView(selectedTab: .constant(0))
}
