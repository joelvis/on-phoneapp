//
//  VaultView.swift
//  On phoneapp
//
//  Created by Joel  on 10/18/25.
//

import SwiftUI

struct VaultView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                // Adaptive background
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue.opacity(0.5))

                    Text("Vault")
                        .font(.title)
                        .fontWeight(.semibold)

                    Text("Your secure vault")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Vault")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    VaultView()
}
