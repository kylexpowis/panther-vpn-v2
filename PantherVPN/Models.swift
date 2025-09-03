//
//  Models.swift
//  PantherVPN
//
//  Created by Kyle Powis on 01/09/2025.
//

// Models.swift (App target)
// Models.swift
import Foundation

struct RegisterResponse: Codable {
    let assignedAddressCIDR: String     // e.g. "10.10.0.2/32"
    let serverPublicKey: String         // WG server pubkey (Base64)
    let endpoint: String                // e.g. "vpn.panthervpn.app:51820"
    let dns: [String]                   // e.g. ["1.1.1.1", "1.0.0.1"]
}
