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
    // For dismissing when pushed/presented
    @Environment(\.dismiss) private var dismiss

    // UI State
    @State private var selectedServer = "Helsinki"  // default to live region
    @State private var showDropdown = false
    @State private var isBusy = false
    @State private var isConnected = false
    @State private var lastError: String?

    // Map overlay animation
    @State private var mapFullHeight: CGFloat = 0     // computed from Helsinki.top -> Tokyo.bottom
    @State private var mapRevealHeight: CGFloat = 0   // animated from 0 -> mapFullHeight

    // Disconnect confirm
    @State private var showDisconnectConfirm = false

    // Shared corner radius for cards/map/button
    private let cardCorner: CGFloat = 16

    struct Server: Identifiable {
        let id = UUID()
        let name: String
        let tag: String?
    }

    // Your server list
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
                                Button("My Account") {
                                    // TODO: push account screen
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 12)

                                Divider().background(Color.white.opacity(0.2))

                                Button("Report an issue") {
                                    // TODO: open issue form
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 12)

                                Divider().background(Color.white.opacity(0.2))

                                Button("Log Out") {
                                    handleLogout()
                                }
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

                    Text(isConnected ? "Connected to \(regionNameForSelectedServer() ?? selectedServer)" : "Select a server")
                        .foregroundColor(.white)
                        .font(.headline)
                        .animation(.easeInOut(duration: 0.25), value: isConnected)

                    // ===== Server selectors with animated overlay & fade-out =====
                    ZStack {
                        // Server cards list (attach anchors on each card)
                        VStack(spacing: 12) {
                            ForEach(servers) { server in
                                serverCard(server, isSelected: server.name == selectedServer)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if !isConnected { selectedServer = server.name }
                                    }
                                    .anchorPreference(key: CardBoundsKey.self, value: .bounds) { anchor in
                                        [server.name: anchor]
                                    }
                            }
                        }
                        // Fade servers out as map reveals
                        .opacity(serverListOpacity)
                        .animation(.easeInOut(duration: 0.8), value: mapRevealHeight)
                        .allowsHitTesting(!isConnected) // don't let user tap cards while connected
                        .zIndex(1) // map will sit above this
                    }
                    .frame(maxWidth: 320)
                    // Read the collected anchors on the SAME container
                    .overlayPreferenceValue(CardBoundsKey.self) { dict in
                        GeometryReader { proxy in
                            let hRect = dict["Helsinki"].map { proxy[$0] }
                            let tRect = dict["Tokyo"].map    { proxy[$0] }

                            if let h = hRect, let t = tRect {
                                let topY = h.minY
                                let bottomY = t.maxY
                                let fullHeight = max(0, bottomY - topY)

                                let mapBase = Image("helsinki_map")
                                    .resizable()
                                    .scaledToFill()
                                    .clipShape(RoundedRectangle(cornerRadius: cardCorner, style: .continuous))

                                mapBase
                                    .frame(width: proxy.size.width, height: fullHeight)
                                    .position(x: proxy.size.width / 2, y: (topY + bottomY) / 2)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: cardCorner, style: .continuous)
                                            .stroke(Color.black.opacity(0.9), lineWidth: 0.6)
                                    )
                                    .zIndex(10)
                                    .onAppear {
                                        self.mapFullHeight = fullHeight
                                        if self.mapRevealHeight > fullHeight { self.mapRevealHeight = fullHeight }
                                    }
                                    .onChange(of: fullHeight) { newVal in
                                        self.mapFullHeight = newVal
                                        if self.mapRevealHeight > newVal { self.mapRevealHeight = newVal }
                                    }
                                    .mask(
                                        VStack {
                                            Spacer()
                                            Rectangle().frame(height: mapRevealHeight) // animated
                                        }
                                    )
                                    .animation(.easeInOut(duration: 1.0), value: mapRevealHeight)
                            }
                        }
                    }

                    // Connect / Connected button (original height; black + green glow when connected)
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
                            RoundedRectangle(cornerRadius: cardCorner)
                                .fill(buttonFillColor)
                        )
                        .overlay(
                            Group {
                                if isConnected {
                                    RoundedRectangle(cornerRadius: cardCorner)
                                        .stroke(Color.green, lineWidth: 2)
                                        .shadow(color: .green.opacity(0.5), radius: 8)
                                        .shadow(color: .green.opacity(0.35), radius: 16)
                                } else if isSelectedServerAvailable {
                                    RoundedRectangle(cornerRadius: cardCorner)
                                        .stroke(Color.accentColor.opacity(0.35), lineWidth: 1)
                                } else {
                                    RoundedRectangle(cornerRadius: cardCorner)
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                }
                            }
                        )
                        .shadow(color: (isConnected ? Color.black : buttonFillColor).opacity(0.35), radius: 10, y: 6)
                    }
                    .disabled(!isSelectedServerAvailable || isBusy)
                    .opacity(!isSelectedServerAvailable ? 0.6 : 1.0)
                    .frame(maxWidth: 320)
                    .animation(.spring(response: 0.28, dampingFraction: 0.9), value: isConnected)
                }

                Spacer()
            }
        }
        // Error alert
        .alert("VPN Error", isPresented: .constant(lastError != nil), actions: {
            Button("OK") { lastError = nil }
        }, message: {
            Text(lastError ?? "")
        })
        // Disconnect confirm alert
        .alert("Disconnect?", isPresented: $showDisconnectConfirm) {
            Button("Yes", role: .destructive) {
                Task { await performDisconnect() }
            }
            Button("No", role: .cancel) {}
        } message: {
            Text("Are you sure you would like to disconnect from the server?")
        }
        .onAppear {
            Task {
                await VPNManager.shared.removeStaleProfiles()
                await refreshStatus()
            }
        }
        .onChange(of: isConnected) { _, newValue in
            if mapFullHeight > 0 {
                if newValue {
                    withAnimation(.easeInOut(duration: 1.1)) {
                        mapRevealHeight = mapFullHeight
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.7)) {
                        mapRevealHeight = 0
                    }
                }
            }
        }
        .onChange(of: mapFullHeight) { _, newVal in
            if newVal > 0, isConnected {
                withAnimation(.easeInOut(duration: 1.1)) { mapRevealHeight = newVal }
            }
        }
    }

    // MARK: - Derived UI

    private var buttonTitle: String {
        guard isSelectedServerAvailable else { return "Coming Soon" }
        if isBusy { return isConnected ? "Disconnecting…" : "Connecting…" }
        return isConnected ? "Connected" : "Connect"
    }

    private var buttonFillColor: Color {
        if isConnected { return .black }
        return isSelectedServerAvailable ? Color.accentColor : .gray
    }

    private var serverListOpacity: Double {
        guard mapFullHeight > 0 else { return isConnected ? 0 : 1 }
        let ratio = min(max(mapRevealHeight / mapFullHeight, 0), 1)
        return Double(1 - ratio)
    }

    private var isSelectedServerAvailable: Bool {
        regionNameForSelectedServer() != nil
    }

    private func regionNameForSelectedServer() -> String? {
        switch selectedServer {
        case "Helsinki": return "Helsinki"
        default:         return nil
        }
    }

    // MARK: - Server Card

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
            RoundedRectangle(cornerRadius: cardCorner)
                .fill(Color.black)
                .shadow(color: isSelected ? Color.accentColor.opacity(0.25) : .black.opacity(0.8),
                        radius: 10, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cardCorner)
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
        if isConnected {
            showDisconnectConfirm = true
            return
        }

        guard let regionName = regionNameForSelectedServer() else { return }
        isBusy = true
        lastError = nil

        Task {
            do {
                print("▶️ Connect tapped for region:", regionName)

                let client = SupabaseManager.shared.client
                let session = try await client.auth.session
                let jwt = session.accessToken

                print("🌐 Calling wg-register…")
                let reg = try await API.registerDevice(regionName: regionName, authToken: jwt)

                await VPNManager.shared.removeStaleProfiles()

                print("🛠️ Installing/updating profile…")
                _ = try await VPNManager.shared.installOrUpdateTunnel(using: reg, regionName: regionName)

                try? await Task.sleep(nanoseconds: 300_000_000)

                print("🔌 Toggling connection…")
                try await VPNManager.shared.toggleConnection()

                try? await Task.sleep(nanoseconds: 600_000_000)
                await refreshStatus()
            } catch {
                let lower = error.localizedDescription.lowercased()
                if lower.contains("subscription_inactive") || lower.contains("403") || lower.contains("forbidden") {
                    await MainActor.run {
                        lastError = "Your subscription is inactive or has expired. Please purchase or renew a plan to connect."
                    }
                } else {
                    await MainActor.run { lastError = error.localizedDescription }
                }
            }
            await MainActor.run { isBusy = false }
        }
    }

    private func handleLogout() {
        showDropdown = false
        isBusy = true

        Task {
            // best-effort disconnect
            if isConnected {
                try? await VPNManager.shared.toggleConnection()
            }

            let client = SupabaseManager.shared.client
            let deviceId = DeviceID.current()

            // remove device record for this install (optional but tidy)
            try? await client.from("devices").delete().eq("device_id", value: deviceId).execute()
            // sign out
            try? await client.auth.signOut()

            await MainActor.run {
                // reset local UI state
                isConnected = false
                selectedServer = "Helsinki"
                mapRevealHeight = 0
                isBusy = false

                // Try to dismiss if this view was pushed/presented
                dismiss()

                // If dismiss does nothing (HomeView is root), hard switch to ContentView
                if let window = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .flatMap({ $0.windows })
                    .first(where: { $0.isKeyWindow }) {

                    window.rootViewController = UIHostingController(rootView: ContentView()
                        .tint(.blue)
                        .preferredColorScheme(.dark)
                    )
                    window.makeKeyAndVisible()
                }
            }
        }
        print("Logging out…")
    }

    private func performDisconnect() async {
        isBusy = true
        defer { isBusy = false }
        do {
            try await VPNManager.shared.toggleConnection()
            try? await Task.sleep(nanoseconds: 400_000_000)
            await refreshStatus()
        } catch {
            await MainActor.run { lastError = error.localizedDescription }
        }
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

// MARK: - PreferenceKey to capture card bounds
private struct CardBoundsKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]
    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

#Preview {
    HomeView()
        .tint(.blue)
        .preferredColorScheme(.dark)
}
















