//
//  HomeView.swift
//  PantherVPN
//
//  Created by Kyle Powis on 06/08/2025.
//

import SwiftUI
import NetworkExtension
import UIKit

struct HomeView: View {
    // UI State
    @State private var selectedServer = "Helsinki"  // default to live region
    @State private var showDropdown = false
    @State private var isBusy = false
    @State private var isConnected = false
    @State private var lastError: String?

    struct Server: Identifiable {
        let id = UUID()
        let name: String
        let tag: String?
    }

    // Your server list (unchanged visuals)
    let servers: [Server] = [
        .init(name: "Helsinki",   tag: nil),
        .init(name: "New York",   tag: "Coming Soon"),
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
                                Button("Copy device pubkey", action: copyPubkey)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 12)

                                Divider().background(Color.white.opacity(0.2))

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

                    // Server selectors
                    VStack(spacing: 12) {
                        ForEach(servers) { server in
                            serverCard(server,
                                       isSelected: server.name == selectedServer)
                                .contentShape(Rectangle())
                                .onTapGesture { selectedServer = server.name }
                        }
                    }
                    .frame(maxWidth: 320)

                    // Connect / Disconnect button
                    Button(action: handleConnect) {
                        HStack(spacing: 8) {
                            if isBusy { ProgressView().tint(.white) }
                            Text(buttonTitle)
                                .foregroundColor(.white)
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.accentColor)
                        )
                        .shadow(color: Color.accentColor.opacity(0.35), radius: 10, y: 6)
                    }
                    .disabled(regionNameForSelectedServer() == nil || isBusy)
                    .opacity((regionNameForSelectedServer() == nil) ? 0.5 : 1.0)
                    .frame(maxWidth: 320)

                    // Status line
                    Text(statusLine)
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()
            }
        }
        .alert("VPN Error", isPresented: .constant(lastError != nil), actions: {
            Button("OK") { lastError = nil }
        }, message: {
            Text(lastError ?? "")
        })
        .onAppear { Task { await refreshStatus() } }
    }

    // MARK: - Derived UI

    private var buttonTitle: String {
        guard regionNameForSelectedServer() != nil else { return "Coming Soon" }
        if isBusy { return isConnected ? "Disconnecting…" : "Connecting…" }
        return isConnected ? "Disconnect" : "Connect"
    }

    private var statusLine: String {
        guard let name = regionNameForSelectedServer() else { return "Selected region is not yet available." }
        return isConnected ? "Connected to \(name)" : "Not connected"
    }

    // Only live region(s) return a name; coming-soon return nil to disable the button
    private func regionNameForSelectedServer() -> String? {
        switch selectedServer {
        case "Helsinki": return "Helsinki"
        default:         return nil
        }
    }

    // MARK: - Server Card (unchanged visuals)
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

    // MARK: - Flags
    private func flagEmoji(for name: String) -> String {
        switch name {
        case "Helsinki":   return "🇫🇮"
        case "New York":   return "🇺🇸"
        case "Stockholm":  return "🇸🇪"
        case "Warsaw":     return "🇵🇱"
        case "Tokyo":      return "🇯🇵"
        default:           return ""
        }
    }

    // MARK: - Actions

    private func handleConnect() {
        guard let regionName = regionNameForSelectedServer() else { return }
        isBusy = true
        lastError = nil

        Task {
            do {
                // 1) get Supabase user access token (non-optional Session)
                let client = SupabaseManager.shared.client
                let session = try await client.auth.session
                let jwt = session.accessToken

                // 2) call your function to register/get config
                let reg = try await API.registerDevice(regionName: regionName, authToken: jwt)

                // 3) save profile and connect/toggle
                _ = try await VPNManager.shared.installOrUpdateTunnel(using: reg, regionName: regionName)
                try await VPNManager.shared.toggleConnection()

                try? await Task.sleep(nanoseconds: 600_000_000)
                await refreshStatus()
            } catch {
                lastError = error.localizedDescription
            }
            isBusy = false
        }
    }

    private func copyPubkey() {
        do {
            let pub = try WGKeyStore.publicKeyBase64()
            UIPasteboard.general.string = pub
            lastError = "Device public key copied to clipboard."
        } catch {
            lastError = "Could not read/generate device key."
        }
        showDropdown = false
    }

    private func handleLogout() {
        Task {
            let client = SupabaseManager.shared.client
            let deviceId = DeviceID.current()
            try? await client.from("devices").delete().eq("device_id", value: deviceId).execute()
            try? await client.auth.signOut()
        }
        print("Logging out…")
    }

    // Poll saved manager for a simple status read
    @MainActor
    private func refreshStatus() async {
        do {
            let managers = try await NETunnelProviderManager.loadAllFromPreferences()
            if let m = managers.first {
                isConnected = (m.connection.status == .connected)
            } else {
                isConnected = false
            }
        } catch {
            isConnected = false
        }
    }
}

#Preview {
    HomeView()
        .tint(.blue)
        .preferredColorScheme(.dark)
}









