//
//  VPNController.swift
//  PantherVPN
//
//  Created by Kyle Powis on 25/08/2025.
//

//  VPNController.swift
//  PantherVPN (App target)
//  Paste this whole file into your app target, not the extension.

import Foundation
import NetworkExtension
import WireGuardKit

// MARK: - Region config (your servers)
enum Region {
    case helsinki

    // Server:Port
    var endpoint: String { "95.216.154.98:51820" }

    // The server's WireGuard public key (Base64).
    // Store your real key in Secrets.helsinkiServerPublicKey
    var serverPubKey: String { Secrets.helsinkiServerPublicKey }

    // Resolver list you want the device to use when tunnel is up
    var dns: [String] { ["1.1.1.1", "1.0.0.1"] }

    var name: String { "Helsinki" }
}

// MARK: - Tiny Keychain helper for device private key
private enum Keychain {
    static let service = "app.panthervpn.client" // match your app bundle id

    static func read(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func write(_ key: String, _ value: String) throws {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        if SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess {
            let attrs: [String: Any] = [kSecValueData as String: data]
            SecItemUpdate(query as CFDictionary, attrs as CFDictionary)
        } else {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }
}

// MARK: - VPN Controller (App-side profile install + connect)
final class VPNController {
    static let shared = VPNController()

    /// MUST exactly match your PacketTunnel extension bundle identifier
    /// (Target: VPNPacketTunnel → General → Bundle Identifier)
    private let providerBundleID = "app.panthervpn.client.packetTunnel"

    // Create or load a persistent device private key (client identity)
    private func loadOrCreateDevicePrivateKey() throws -> PrivateKey {
        if let stored = Keychain.read("wg-device-private-key"),
           let key = PrivateKey(base64Key: stored) {
            return key
        }
        let newKey = PrivateKey()
        try Keychain.write("wg-device-private-key", newKey.base64Key)
        return newKey
    }

    /// Install or update the VPN profile in iOS preferences for the given region.
    /// Shows the iOS "Allow to add VPN configurations?" prompt the first time.
    @MainActor
    func prepare(region: Region) async throws -> NETunnelProviderManager {
        let priv = try loadOrCreateDevicePrivateKey()

        // Compose a real wg-quick payload (mirror what worked in the WireGuard app)
        let wgQuick = """
        [Interface]
        PrivateKey = \(priv.base64Key)
        Address = 10.0.0.2/32
        DNS = \(region.dns.joined(separator: ", "))
        # MTU = 1420

        [Peer]
        PublicKey = \(region.serverPubKey)
        AllowedIPs = 0.0.0.0/0, ::/0
        Endpoint = \(region.endpoint)
        PersistentKeepalive = 25
        """

        // Build provider protocol and pass wg-quick to the extension
        let proto = NETunnelProviderProtocol()
        proto.providerBundleIdentifier = providerBundleID
        proto.serverAddress = region.name         // any non-empty label
        proto.providerConfiguration = ["WgQuickConfig": wgQuick]

        // Load / create manager, save, and reload
        let managers = try await NETunnelProviderManager.loadAllFromPreferences()
        let manager = managers.first ?? NETunnelProviderManager()
        manager.localizedDescription = "PantherVPN"
        manager.protocolConfiguration = proto
        manager.isEnabled = true

        try await manager.saveToPreferences()
        try await manager.loadFromPreferences()
        return manager
    }

    /// Start the tunnel (launches the PacketTunnel extension)
    @MainActor
    func connect() async throws {
        let managers = try await NETunnelProviderManager.loadAllFromPreferences()
        guard let manager = managers.first else {
            throw NSError(domain: "VPN", code: -2, userInfo: [NSLocalizedDescriptionKey: "No saved manager"])
        }
        guard let session = manager.connection as? NETunnelProviderSession else {
            throw NSError(domain: "VPN", code: -3, userInfo: [NSLocalizedDescriptionKey: "Missing NETunnelProviderSession"])
        }
        try session.startTunnel()
    }

    /// Stop the tunnel if running
    @MainActor
    func disconnect() async {
        let managers = try? await NETunnelProviderManager.loadAllFromPreferences()
        let session = managers?.first?.connection as? NETunnelProviderSession
        session?.stopTunnel()
    }

    /// Convenience: show this on-screen once so you can add the device to the WG server
    func devicePublicKeyBase64() -> String? {
        guard let base64 = Keychain.read("wg-device-private-key"),
              let priv = PrivateKey(base64Key: base64) else { return nil }
        return priv.publicKey.base64Key
    }
}


