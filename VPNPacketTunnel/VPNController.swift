//
//  VPNController.swift
//  PantherVPN
//
//  Created by Kyle Powis on 25/08/2025.
//

import Foundation
import NetworkExtension
import WireGuardKit

// MARK: - Region config you control
enum Region {
    case helsinki

    var endpoint: String { "95.216.154.98:51820" }        // server:port
    var serverPubKey: String { "<SERVER_PUBLIC_KEY_BASE64>" }
    var dns: [String] { ["1.1.1.1", "1.0.0.1"] }
    var name: String { "Helsinki" }
}

// MARK: - Simple Keychain helper (no 3rd-party lib)
private enum Keychain {
    static let service = "com.yourcompany.yourapp.vpn"      // change to your bundle base

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
        // Update if exists
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

// MARK: - Controller
final class VPNController {
    static let shared = VPNController()

    // MUST exactly match your PacketTunnel extension bundle id
    private let providerBundleID = "app.panthervpn.client.packetTunnel"

    // Create or load a persistent device key for WireGuard
    private func loadOrCreateDevicePrivateKey() throws -> PrivateKey {
        if let stored = Keychain.read("wg-device-private-key"),
           let key = PrivateKey(base64Key: stored) {
            return key
        }
        let newKey = PrivateKey()
        try Keychain.write("wg-device-private-key", newKey.base64Key)
        return newKey
    }

    /// Create/update the NETunnelProviderManager with a WireGuard config
    func prepare(region: Region) async throws -> NETunnelProviderManager {
        let priv = try loadOrCreateDevicePrivateKey()

        // Interface = device identity + local settings inside the tunnel
        var interface = InterfaceConfiguration(privateKey: priv)
        if let addr = IPAddressRange(from: "10.0.0.2/32") {
            interface.addresses = [addr]
        }
        interface.dns = region.dns.compactMap { DNSServer(from: $0) }


        // Peer = your server
        guard let pub = PublicKey(base64Key: region.serverPubKey) else {
            throw NSError(domain: "VPN", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid server public key"])
        }

        var peer = PeerConfiguration(publicKey: pub)
        if let all = IPAddressRange(from: "0.0.0.0/0") {
            peer.allowedIPs = [all]
        }
        // not throwing – remove try
        peer.endpoint = Endpoint(from: region.endpoint)
        peer.persistentKeepAlive = 25

        // You can keep tunnelConfig if you like, but we’ll build wg-quick text directly
        let tunnelConfig = TunnelConfiguration(name: region.name,
                                               interface: interface,
                                               peers: [peer])

        // Build wg-quick text manually (what the provider actually reads)
        let wgQuick = """
        [Interface]
        PrivateKey = \(priv.base64Key)
        Address = 10.0.0.2/32
        DNS = \(region.dns.joined(separator: ", "))

        [Peer]
        PublicKey = \(region.serverPubKey)
        AllowedIPs = 0.0.0.0/0
        Endpoint = \(region.endpoint)
        PersistentKeepalive = 25
        """

        // Convert to provider protocol used by the packet tunnel
        let proto = NETunnelProviderProtocol()
        proto.providerBundleIdentifier = providerBundleID
        proto.providerConfiguration = ["WgQuickConfig": wgQuick]   // ← replace asWgQuickConfig().asData()
        proto.serverAddress = region.name

        // Load or create a manager and apply proto
        let managers = try await NETunnelProviderManager.loadAllFromPreferences()
        let manager = managers.first ?? NETunnelProviderManager()
        manager.localizedDescription = "PantherVPN"
        manager.protocolConfiguration = proto
        manager.isEnabled = true
        try await manager.saveToPreferences()

        return manager
    }
}

