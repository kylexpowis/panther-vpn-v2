//
//  Region.swift
//  PantherVPN
//
//  Created by Kyle Powis on 01/09/2025.
//


// Region.swift (App target)
import Foundation

/// Only what the user chooses. The server will return serverPubKey/endpoint/dns.
enum Region: String, Codable, CaseIterable, Identifiable {
    case helsinki = "Helsinki"
    // add more when you launch them: case newYork = "New York"

    var id: String { rawValue }
    var name: String { rawValue }
}
