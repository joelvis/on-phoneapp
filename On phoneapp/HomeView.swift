//
//  HomeView.swift
//  On phoneapp
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
            // Darker blue background
            Color(red: 0.1, green: 0.2, blue: 0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                // Welcome text
                Text("Welcome")
                    .font(.system(.largeTitle, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                // Time display
                Text(currentTime, style: .time)
                    .font(.system(size: 72, weight: .thin, design: .rounded))
                    .foregroundColor(.white)

                // Date display
                Text(currentTime, format: .dateTime.weekday(.wide).month().day().year())
                    .font(.system(.title3, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))

                Spacer()
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
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

