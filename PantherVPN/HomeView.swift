//
//  HomeView.swift
//  PantherVPN
//
//  Created by Kyle Powis on 06/08/2025.
//

import SwiftUI

struct HomeView: View {
    @State private var selectedServer = "New York"   // match list name
    @State private var showDropdown = false

    struct Server: Identifiable {
        let id = UUID()
        let name: String
        let tag: String?
    }

    let servers: [Server] = [
        .init(name: "New York",   tag: nil),
        .init(name: "Stockholm",  tag: "Coming Soon"),
        .init(name: "Warsaw",     tag: "Coming Soon"),
        .init(name: "Tokyo",      tag: "Coming Soon")
    ]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            VStack {
                // Top-right gear + dropdown
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 10) {
                        Button(action: { withAnimation(.spring(response: 0.25)) { showDropdown.toggle() } }) {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.white)
                                .font(.title2)
                                .padding(.top, 20)
                                .padding(.trailing, 20)
                        }

                        if showDropdown {
                            VStack(alignment: .leading, spacing: 0) {
                                Button("Log Out", action: handleLogout)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 12)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.black)
                                    .shadow(color: Color.accentColor.opacity(0.25), radius: 10, y: 6)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.6), lineWidth: 1)
                            )
                            .padding(.trailing)
                        }
                    }
                }

                Spacer()

                // Main content
                VStack(spacing: 24) {
                    Image("transparentpanthertemplogo")
                        .resizable()
                        .frame(width: 120, height: 120)
                        .aspectRatio(contentMode: .fit)

                    Image("panthertextlogo1")
                        .resizable()
                        .frame(width: 220, height: 32)
                        .aspectRatio(contentMode: .fit)

                    Text("Select a server")
                        .foregroundColor(.white)
                        .font(.headline)

                    // Server selectors (stacked cards with tags + flag)
                    VStack(spacing: 12) {
                        ForEach(servers) { server in
                            serverCard(server,
                                       isSelected: server.name == selectedServer)
                            .contentShape(Rectangle()) // make entire card tappable
                            .onTapGesture { selectedServer = server.name } // allow selecting any server
                        }
                    }
                    .frame(maxWidth: 320)

                    // Connect button
                    Button(action: handleConnect) {
                        Text("Connect")
                            .foregroundColor(.white)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.accentColor)
                            )
                            .shadow(color: Color.accentColor.opacity(0.35), radius: 10, y: 6)
                    }
                    .frame(maxWidth: 320)
                }

                Spacer()
            }
        }
    }

    // MARK: - Server Card (with tag + right-side flag emoji only)
    @ViewBuilder
    private func serverCard(_ server: Server, isSelected: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(isSelected ? Color.accentColor : .gray)

            Text(server.name)
                .font(.headline)
                .foregroundColor(.white)

            if let tag = server.tag {
                Text(tag)
                    .font(.caption2).bold()
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Capsule().fill(Color.accentColor.opacity(0.15)))
                    .foregroundColor(Color.accentColor)
            }

            Spacer()

            // Flag emoji on the right (no circle background)
            Text(flagEmoji(for: server.name))
                .font(.system(size: 22))
                .padding(.trailing, 4)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black)
                .shadow(color: isSelected ? Color.accentColor.opacity(0.25) : .black.opacity(0.8),
                        radius: 10, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.6), lineWidth: 1)
        )
    }

    // MARK: - Flag mapping
    private func flagEmoji(for name: String) -> String {
        switch name {
        case "New York":   return "🇺🇸"
        case "Stockholm":  return "🇸🇪"
        case "Warsaw":     return "🇵🇱"
        case "Tokyo":      return "🇯🇵"
        default:           return ""
        }
    }

    // MARK: - Actions
    func handleConnect() {
        print("Connecting to \(selectedServer)")
    }

    func handleLogout() {
        print("Logging out…")
        // Add Supabase logout logic later
    }
}

#Preview {
    HomeView()
        .tint(.blue)
        .preferredColorScheme(.dark)
}





