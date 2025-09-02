//
//  PacketTunnelProvider.swift
//  VPNPacketTunnel
//
//  Created by Kyle Powis on 25/08/2025.
//

import NetworkExtension

final class PacketTunnelProvider: NEPacketTunnelProvider {
    
    override func startTunnel(options: [String : NSObject]?,
                              completionHandler: @escaping (Error?) -> Void) {
        
        // Grab wg-quick style config from providerConfiguration
        guard
            let proto = protocolConfiguration as? NETunnelProviderProtocol,
            let config = proto.providerConfiguration?["WgQuickConfig"] as? String
        else {
            completionHandler(NSError(domain: "PacketTunnel", code: -1,
                                      userInfo: [NSLocalizedDescriptionKey: "Missing WgQuickConfig"]))
            return
        }
        
        // TODO: Parse `config` and bring up WireGuard interface here
        // You likely already have WireGuardKit integrated, so this is where
        // you'd hand off to WG routines with `config`.
        
        // Minimal placeholder so iOS thinks the tunnel is up
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        settings.ipv4Settings = NEIPv4Settings(addresses: ["10.0.0.2"], subnetMasks: ["255.255.255.255"])
        settings.dnsSettings = NEDNSSettings(servers: ["1.1.1.1"])
        
        setTunnelNetworkSettings(settings) { error in
            completionHandler(error)
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason,
                             completionHandler: @escaping () -> Void) {
        // Stop your WireGuard process here if running
        completionHandler()
    }
    
    override func handleAppMessage(_ messageData: Data,
                                   completionHandler: ((Data?) -> Void)?) {
        completionHandler?(messageData) // echo back
    }
    
    override func sleep(completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    override func wake() {
        // Called when device wakes up
    }
}

