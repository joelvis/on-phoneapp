//
//  HomeView.swift
//  On phoneapp
//
//  Redesigned with Steve Jobs design principles
//

import SwiftUI
import Combine

struct HomeView: View {
    @Binding var selectedTab: Int
    @State private var currentTime = Date()
    @State private var showContent = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    init(selectedTab: Binding<Int>) {
        self._selectedTab = selectedTab
    }

    var body: some View {
        ZStack {
            // Premium gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.08),
                    Color(red: 0.12, green: 0.12, blue: 0.18)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Subtle ambient glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.blue.opacity(0.15),
                            Color.clear
                        ],
                        center: .top,
                        startRadius: 0,
                        endRadius: 400
                    )
                )
                .frame(width: 600, height: 600)
                .offset(y: -200)
                .blur(radius: 40)
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 2.0), value: showContent)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Hero section with time
                    VStack(spacing: 12) {
                        // App wordmark
                        Text("On Phone")
                            .font(.system(size: 28, weight: .medium, design: .default))
                            .foregroundColor(.white.opacity(0.95))
                            .tracking(0.5)
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : -20)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1), value: showContent)
                        
                        // Live time - Hero element
                        Text(currentTime, style: .time)
                            .font(.system(size: 88, weight: .thin, design: .default))
                            .foregroundColor(.white)
                            .opacity(showContent ? 1 : 0)
                            .scaleEffect(showContent ? 1 : 0.8)
                            .blur(radius: showContent ? 0 : 20)
                            .animation(.spring(response: 1.0, dampingFraction: 0.75).delay(0.3), value: showContent)
                        
                        // Date
                        Text(currentTime, format: .dateTime.weekday(.wide).month().day())
                            .font(.system(size: 17, weight: .regular, design: .default))
                            .foregroundColor(.white.opacity(0.6))
                            .tracking(0.3)
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.5), value: showContent)
                    }
                    .padding(.top, 80)
                    .padding(.bottom, 60)
                    
                    // Quick actions
                    VStack(spacing: 16) {
                        QuickActionCard(
                            icon: "lock.doc.fill",
                            title: "Vault",
                            subtitle: "Secure documents",
                            accentColor: Color(red: 0.3, green: 0.4, blue: 1.0),
                            delay: 0.7
                        )
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 30)
                        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.7), value: showContent)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = 3 // Vault tab
                            }
                        }
                        
                        QuickActionCard(
                            icon: "note.text",
                            title: "Notes",
                            subtitle: "Quick thoughts",
                            accentColor: Color(red: 1.0, green: 0.8, blue: 0.0),
                            delay: 0.85
                        )
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 30)
                        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.85), value: showContent)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = 1 // Notes tab
                            }
                        }
                        
                        QuickActionCard(
                            icon: "checklist",
                            title: "Tasks",
                            subtitle: "Stay organized",
                            accentColor: Color(red: 0.2, green: 0.8, blue: 0.4),
                            delay: 1.0
                        )
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 30)
                        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(1.0), value: showContent)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = 2 // Tasks tab
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .onAppear {
            withAnimation {
                showContent = true
            }
        }
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let accentColor: Color
    let delay: Double

    var body: some View {
        HStack(spacing: 16) {
            // Icon container
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 56, height: 56)
                
            Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(accentColor)
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .default))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            // Arrow indicator
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
    }
}

#Preview {
    HomeView(selectedTab: .constant(0))
}
