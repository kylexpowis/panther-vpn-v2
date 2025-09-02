//
//  API.swift
//  PantherVPN
//
//  Created by Kyle Powis on 01/09/2025.
//


// API.swift
import Foundation

enum API {
    // Replace PROJECT_REF with your Supabase project ref
    private static let base = URL(string: "https://porfljfbepodmqfatutn.supabase.co/functions/v1")!

    struct RegisterResponse: Codable {
        let assignedAddressCIDR: String
        let serverPublicKey: String
        let endpoint: String
        let dns: [String]
    }

    static func registerDevice(regionName: String, authToken: String) async throws -> RegisterResponse {
        let pubKey = try WGKeyStore.publicKeyBase64()
        let deviceId = DeviceID.current()

        var req = URLRequest(url: base.appendingPathComponent("wg-register")) // <-- no leading slash
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "deviceId": deviceId,
            "publicKey": pubKey,
            "region": regionName
        ])

        print("▶️ API:", req.url!.absoluteString)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Server error"
            throw NSError(domain: "API", code: (resp as? HTTPURLResponse)?.statusCode ?? -1,
                          userInfo: [NSLocalizedDescriptionKey: msg])
        }
        return try JSONDecoder().decode(RegisterResponse.self, from: data)
    }
}

