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

    /// MUST exactly match your PacketTunnel extension bundle identifier
    private let providerBundleID = "app.panthervpn.client.packetTunnel"

    /// Install or update the tunnel using values returned by the wg-register Edge Function.
    /// NOTE: We explicitly use `API.RegisterResponse` (not a global type) to avoid ambiguity.
    @discardableResult
    func installOrUpdateTunnel(using reg: API.RegisterResponse,
                               regionName: String) async throws -> NETunnelProviderManager {

        // Build wg-quick payload from backend response
        let wgQuick = """
        [Interface]
        PrivateKey = \(try WGKeyStore.privateKeyBase64())
        Address = \(reg.assignedAddressCIDR)
        DNS = \(reg.dns.joined(separator: ", "))

        [Peer]
        PublicKey = \(reg.serverPublicKey)
        AllowedIPs = 0.0.0.0/0, ::/0
        Endpoint = \(reg.endpoint)
        PersistentKeepalive = 25
        """

        let proto = NETunnelProviderProtocol()
        proto.providerBundleIdentifier = providerBundleID
        proto.serverAddress = regionName           // label shown in Settings
        proto.providerConfiguration = ["WgQuickConfig": wgQuick]

        let managers = try await NETunnelProviderManager.loadAllFromPreferences()
        let manager = managers.first ?? NETunnelProviderManager()
        manager.localizedDescription = "PantherVPN"
        manager.protocolConfiguration = proto
        manager.isEnabled = true

        try await manager.saveToPreferences()
        try await manager.loadFromPreferences()
        return manager
    }

    /// Start if stopped, stop if started.
    func toggleConnection() async throws {
        let managers = try await NETunnelProviderManager.loadAllFromPreferences()
        guard let manager = managers.first else {
            throw NSError(domain: "VPN", code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "No saved VPN profile"])
        }
        if let session = manager.connection as? NETunnelProviderSession {
            switch session.status {
            case .connected, .connecting, .reasserting:
                session.stopTunnel()
            default:
                try session.startTunnel()
            }
        } else {
            throw NSError(domain: "VPN", code: -3,
                          userInfo: [NSLocalizedDescriptionKey: "No tunnel session"])
        }
    }
}






