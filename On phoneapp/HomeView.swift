//
//  HomeView.swift
//  Toolbox
//
//  Created by Joel  on 10/18/25.
//

import SwiftUI
import Combine

struct HomeView: View {
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.08, green: 0.15, blue: 0.35),
                    Color(red: 0.15, green: 0.25, blue: 0.45)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Dimmed toolbox outline background
            DimmedToolboxOutline()
                .opacity(0.08)
                .offset(y: 50)

            // Content
            VStack(spacing: 30) {
                Spacer()

                // App title
                VStack(spacing: 8) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Toolbox")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.9)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .padding(.bottom, 20)

                // Time display with modern styling
                VStack(spacing: 8) {
                    Text(currentTime, style: .time)
                        .font(.system(size: 80, weight: .ultraLight, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)

                    // Date display
                    Text(currentTime, format: .dateTime.weekday(.wide).month().day().year())
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.85))
                        .tracking(1)
                }

                Spacer()

                // Subtle tagline
                Text("Your essential toolkit")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(2)
                    .textCase(.uppercase)
                    .padding(.bottom, 40)
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .statusBarHidden(true)
    }
}

// MARK: - Dimmed Toolbox Outline
struct DimmedToolboxOutline: View {
    var body: some View {
        Canvas { context, size in
            let width = size.width
            let height = size.height
            let centerX = width / 2
            let centerY = height / 2

            // Toolbox body dimensions
            let boxWidth: CGFloat = width * 0.6
            let boxHeight: CGFloat = height * 0.35
            let boxX = centerX - boxWidth / 2
            let boxY = centerY - boxHeight / 2

            // Main toolbox body (rectangle)
            let bodyPath = Path { path in
                let rect = CGRect(x: boxX, y: boxY, width: boxWidth, height: boxHeight)
                path.addRoundedRect(in: rect, cornerSize: CGSize(width: 8, height: 8))
            }

            // Handle on top
            let handleWidth: CGFloat = boxWidth * 0.4
            let handleHeight: CGFloat = height * 0.08
            let handleX = centerX - handleWidth / 2
            let handleY = boxY - handleHeight - 5

            let handlePath = Path { path in
                // Handle arc
                path.move(to: CGPoint(x: handleX, y: handleY + handleHeight))
                path.addQuadCurve(
                    to: CGPoint(x: handleX + handleWidth, y: handleY + handleHeight),
                    control: CGPoint(x: centerX, y: handleY - handleHeight * 0.5)
                )
            }

            // Horizontal divider in middle of box
            let dividerPath = Path { path in
                path.move(to: CGPoint(x: boxX, y: centerY))
                path.addLine(to: CGPoint(x: boxX + boxWidth, y: centerY))
            }

            // Vertical dividers creating compartments
            let leftDividerPath = Path { path in
                path.move(to: CGPoint(x: boxX + boxWidth * 0.33, y: boxY))
                path.addLine(to: CGPoint(x: boxX + boxWidth * 0.33, y: boxY + boxHeight))
            }

            let rightDividerPath = Path { path in
                path.move(to: CGPoint(x: boxX + boxWidth * 0.67, y: boxY))
                path.addLine(to: CGPoint(x: boxX + boxWidth * 0.67, y: boxY + boxHeight))
            }

            // Latch clasp
            let latchWidth: CGFloat = boxWidth * 0.15
            let latchHeight: CGFloat = height * 0.04
            let latchX = centerX - latchWidth / 2
            let latchY = boxY + boxHeight - 5

            let latchPath = Path { path in
                let rect = CGRect(x: latchX, y: latchY, width: latchWidth, height: latchHeight)
                path.addRoundedRect(in: rect, cornerSize: CGSize(width: 3, height: 3))
            }

            // Draw all parts with white stroke
            context.stroke(bodyPath, with: .color(.white), lineWidth: 2.5)
            context.stroke(handlePath, with: .color(.white), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            context.stroke(dividerPath, with: .color(.white), lineWidth: 1.5)
            context.stroke(leftDividerPath, with: .color(.white), lineWidth: 1.5)
            context.stroke(rightDividerPath, with: .color(.white), lineWidth: 1.5)
            context.stroke(latchPath, with: .color(.white), lineWidth: 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct BirdStickFigureLogo: View {
    var body: some View {
        Canvas { context, size in
            let width = size.width
            let height = size.height

            // Bird body (vertical line)
            let bodyPath = Path { path in
                path.move(to: CGPoint(x: width * 0.5, y: height * 0.35))
                path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.75))
            }

            // Bird head (circle)
            let headCenter = CGPoint(x: width * 0.5, y: height * 0.25)
            let headRadius = width * 0.12
            let headPath = Path(ellipseIn: CGRect(
                x: headCenter.x - headRadius,
                y: headCenter.y - headRadius,
                width: headRadius * 2,
                height: headRadius * 2
            ))

            // Bird beak (small triangle)
            let beakPath = Path { path in
                path.move(to: CGPoint(x: width * 0.62, y: height * 0.25))
                path.addLine(to: CGPoint(x: width * 0.72, y: height * 0.23))
                path.addLine(to: CGPoint(x: width * 0.62, y: height * 0.27))
                path.closeSubpath()
            }

            // Wings (angled lines from body)
            let leftWingPath = Path { path in
                path.move(to: CGPoint(x: width * 0.5, y: height * 0.45))
                path.addLine(to: CGPoint(x: width * 0.25, y: height * 0.35))
            }

            let rightWingPath = Path { path in
                path.move(to: CGPoint(x: width * 0.5, y: height * 0.45))
                path.addLine(to: CGPoint(x: width * 0.75, y: height * 0.35))
            }

            // Legs (two lines from bottom of body)
            let leftLegPath = Path { path in
                path.move(to: CGPoint(x: width * 0.5, y: height * 0.75))
                path.addLine(to: CGPoint(x: width * 0.4, y: height * 0.9))
            }

            let rightLegPath = Path { path in
                path.move(to: CGPoint(x: width * 0.5, y: height * 0.75))
                path.addLine(to: CGPoint(x: width * 0.6, y: height * 0.9))
            }

            // Feet (small horizontal lines)
            let leftFootPath = Path { path in
                path.move(to: CGPoint(x: width * 0.35, y: height * 0.9))
                path.addLine(to: CGPoint(x: width * 0.45, y: height * 0.9))
            }

            let rightFootPath = Path { path in
                path.move(to: CGPoint(x: width * 0.55, y: height * 0.9))
                path.addLine(to: CGPoint(x: width * 0.65, y: height * 0.9))
            }

            // Draw all parts
            context.stroke(bodyPath, with: .color(.primary), lineWidth: 3)
            context.fill(headPath, with: .color(.primary))
            context.fill(beakPath, with: .color(.orange))
            context.stroke(leftWingPath, with: .color(.primary), lineWidth: 3)
            context.stroke(rightWingPath, with: .color(.primary), lineWidth: 3)
            context.stroke(leftLegPath, with: .color(.primary), lineWidth: 2.5)
            context.stroke(rightLegPath, with: .color(.primary), lineWidth: 2.5)
            context.stroke(leftFootPath, with: .color(.primary), lineWidth: 2.5)
            context.stroke(rightFootPath, with: .color(.primary), lineWidth: 2.5)

            // Eye (small white circle)
            let eyePath = Path(ellipseIn: CGRect(
                x: width * 0.52,
                y: height * 0.23,
                width: width * 0.04,
                height: width * 0.04
            ))
            context.fill(eyePath, with: .color(.white))
        }
    }
}

struct QuickAccessCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [color, color.opacity(0.7)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(16)
    }
}

#Preview {
    HomeView()
}

