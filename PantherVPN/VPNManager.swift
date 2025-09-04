//
//  VPNManager.swift
//  PantherVPN
//
//  Created by Kyle Powis on 30/08/2025.
//

import Foundation
import NetworkExtension

@MainActor
final class VPNManager {
    static let shared = VPNManager()

    // MARK: - Provider bundle id (from Info.plist)
    private var providerBundleID: String {
        if
            let id = Bundle.main.object(forInfoDictionaryKey: "PacketTunnelBundleIdentifier") as? String,
            !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            return id
        }
        // Fallback: keep in sync with your VPNPacketTunnel target if you ever rename it
        return "app.panthervpn.client.packetTunnel"
    }

    // MARK: - Public

    /// Remove saved managers that do not point at the current PacketTunnel extension.
    /// Run once on app start (or before first install) to avoid the "Update Required" profile.
    func removeStaleProfiles() async {
        do {
            let managers = try await NETunnelProviderManager.loadAllFromPreferences()
            for m in managers {
                let pid = (m.protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier
                if pid != providerBundleID {
                    try? await m.removeFromPreferences()
                }
            }
        } catch {
            // non-fatal – keep going
        }
    }

    /// Create or update the VPN profile using values returned by your Edge Function.
    @discardableResult
    func installOrUpdateTunnel(using reg: API.RegisterResponse,
                               regionName: String) async throws -> NETunnelProviderManager {

        // === Structured providerConfiguration (no wg-quick text) ===
        let privateKeyB64 = try WGKeyStore.privateKeyBase64()

        let providerConfig: [String: Any] = [
            "name": "Panther - \(regionName)",
            "interface": [
                "privateKey": privateKeyB64,
                "addresses": [reg.assignedAddressCIDR],
                "dns": reg.dns,                           // e.g. ["1.1.1.1", "1.0.0.1"]
                // Optional:
                // "mtu": 1280,
                // "listenPort": 51820
            ],
            "peers": [[
                "publicKey": reg.serverPublicKey,
                // "presharedKey": reg.presharedKey,      // if your API returns one
                "allowedIPs": ["0.0.0.0/0", "::/0"],
                "endpoint": reg.endpoint,                // "host:51820"
                "persistentKeepalive": 25
            ]]
        ]

        // Configure the provider for our Packet Tunnel extension
        let proto = NETunnelProviderProtocol()
        proto.providerBundleIdentifier = providerBundleID
        proto.serverAddress = "PantherVPN-\(regionName)"   // label shown in Settings
        proto.providerConfiguration = providerConfig

        // Reuse the first manager if it exists, else create one
        let managers = try await NETunnelProviderManager.loadAllFromPreferences()
        let manager = managers.first ?? NETunnelProviderManager()
        manager.localizedDescription = "PantherVPN"
        manager.protocolConfiguration = proto
        manager.isEnabled = true

        // Debug: verify the bundle id used in the profile
        print("📦 providerBundleID (from Info.plist) =", providerBundleID)
        if let protoPid = proto.providerBundleIdentifier {
            print("📦 proto.providerBundleIdentifier =", protoPid)
        }

        // Save + reload so the profile is committed to Settings
        try await manager.saveToPreferences()
        try await manager.loadFromPreferences()

        // Debug: read back what iOS actually stored
        let savedManagers = try await NETunnelProviderManager.loadAllFromPreferences()
        let savedPID = (savedManagers.first?.protocolConfiguration as? NETunnelProviderProtocol)?
            .providerBundleIdentifier ?? "nil"
        print("✅ Saved profile providerBundleIdentifier =", savedPID)

        return manager
    }

    /// Toggle connection state (start if stopped, stop if running).
    func toggleConnection() async throws {
        let managers = try await NETunnelProviderManager.loadAllFromPreferences()
        guard let manager = managers.first else {
            throw NSError(domain: "VPN", code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "No saved VPN profile"])
        }
        guard let session = manager.connection as? NETunnelProviderSession else {
            throw NSError(domain: "VPN", code: -3,
                          userInfo: [NSLocalizedDescriptionKey: "No tunnel session"])
        }

        switch session.status {
        case .connected, .connecting, .reasserting:
            session.stopTunnel()
        default:
            try session.startTunnel()
        }
    }

    /// Current connection status (for UI).
    func currentStatus() async -> NEVPNStatus {
        do {
            let managers = try await NETunnelProviderManager.loadAllFromPreferences()
            return managers.first?.connection.status ?? .invalid
        } catch {
            return .invalid
        }
    }

    // MARK: - Optional one-shot helper (use once then remove)
    /*
    func nukeAllProfiles() async {
        do {
            let ms = try await NETunnelProviderManager.loadAllFromPreferences()
            for m in ms { try await m.removeFromPreferences() }
            print("🧹 Removed \(ms.count) old profiles")
        } catch {
            print("nuke error:", error)
        }
    }
    */
}










