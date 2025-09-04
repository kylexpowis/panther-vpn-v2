//
//  PacketTunnelProvider.swift
//  VPNPacketTunnel
//
//  Created by Kyle Powis on 25/08/2025.
//

import NetworkExtension
import os.log
import WireGuardKit

final class PacketTunnelProvider: NEPacketTunnelProvider {
    private var adapter: WireGuardAdapter?

    override func startTunnel(options: [String : NSObject]? = nil,
                              completionHandler: @escaping (Error?) -> Void) {

        // 1) Pull structured config from the app
        guard
            let proto = protocolConfiguration as? NETunnelProviderProtocol,
            let cfgDict = proto.providerConfiguration as? [String: Any],
            let ifaceDict = cfgDict["interface"] as? [String: Any],
            let peersArr  = cfgDict["peers"] as? [[String: Any]]
        else {
            completionHandler(NSError(domain: "PacketTunnel", code: -1,
                                      userInfo: [NSLocalizedDescriptionKey: "Missing providerConfiguration"]))
            return
        }

        // 2) Interface
        guard
            let privKeyB64 = ifaceDict["privateKey"] as? String,
            let privateKey = PrivateKey(base64Key: privKeyB64)
        else {
            completionHandler(NSError(domain: "PacketTunnel", code: -2,
                                      userInfo: [NSLocalizedDescriptionKey: "Missing/invalid interface.privateKey"]))
            return
        }

        let addressRanges: [IPAddressRange] =
            (ifaceDict["addresses"] as? [String] ?? []).compactMap { IPAddressRange(from: $0) }

        let dnsServers: [DNSServer] =
            (ifaceDict["dns"] as? [String] ?? []).compactMap { DNSServer(from: $0) }

        var interface = InterfaceConfiguration(privateKey: privateKey)
        if !addressRanges.isEmpty { interface.addresses = addressRanges }
        if !dnsServers.isEmpty   { interface.dns = dnsServers }
        if let mtu = ifaceDict["mtu"] as? Int        { interface.mtu = UInt16(mtu) }
        if let lp  = ifaceDict["listenPort"] as? Int { interface.listenPort = UInt16(lp) }

        // 3) Peers
        var peers: [PeerConfiguration] = []
        for dict in peersArr {
            guard
                let pubB64 = dict["publicKey"] as? String,
                let publicKey = PublicKey(base64Key: pubB64)
            else {
                completionHandler(NSError(domain: "PacketTunnel", code: -3,
                                          userInfo: [NSLocalizedDescriptionKey: "Peer missing/invalid publicKey"]))
                return
            }

            let allowed: [IPAddressRange] =
                (dict["allowedIPs"] as? [String] ?? []).compactMap { IPAddressRange(from: $0) }

            var peer = PeerConfiguration(publicKey: publicKey)
            if !allowed.isEmpty { peer.allowedIPs = allowed }

            // NOTE: Your fork doesn’t expose these as public members; skip them.
            // If your types do have them but with different names, we can set them there.
            /*
            if let pskB64 = dict["presharedKey"] as? String,
               let psk = PreSharedKey(base64Key: pskB64) {
                peer.preSharedKey = psk // or peer.presharedKey depending on your fork
            }
            if let keep = dict["persistentKeepalive"] as? Int {
                peer.persistentKeepalive = UInt16(keep)
            }
            */

            if let endpointStr = dict["endpoint"] as? String,
               let endpoint = Endpoint(from: endpointStr) {
                peer.endpoint = endpoint
            }

            peers.append(peer)
        }

        let name = (cfgDict["name"] as? String) ?? "Panther"
        let tunnelConfig = TunnelConfiguration(name: name, interface: interface, peers: peers)

        // 4) Start adapter
        let logHandler: (WireGuardLogLevel, String) -> Void = { _, message in
            os_log("%{public}@", log: .default, type: .default, message)
        }
        adapter = WireGuardAdapter(with: self, logHandler: logHandler)

        adapter?.start(tunnelConfiguration: tunnelConfig) { wgErr in
            // startTunnel's completion expects Error?
            completionHandler(wgErr)
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason,
                             completionHandler: @escaping () -> Void) {
        // Wrap the adapter's expected signature to your () -> Void completion
        adapter?.stop { _ in completionHandler() }
    }
}






