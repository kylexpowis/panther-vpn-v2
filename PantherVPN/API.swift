//
//  API.swift
//  PantherVPN
//
//  Created by Kyle Powis on 01/09/2025.
//


// API.swift
// API.swift
import Foundation

enum API {
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

        var req = URLRequest(url: base.appendingPathComponent("wg-register"))
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "deviceId": deviceId,
            "publicKey": pubKey,
            "region": regionName
        ])

        // 🔊 DEBUG
        print("API → \(req.httpMethod ?? "POST") \(req.url!.absoluteString)")
        if let body = req.httpBody {
            print("API body:", String(data: body, encoding: .utf8) ?? "<binary>")
        }

        let (data, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
        print("API status:", code)
        print("API resp:", String(data: data, encoding: .utf8) ?? "<non-utf8>")

        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Server error"
            throw NSError(domain: "API", code: code, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        return try JSONDecoder().decode(RegisterResponse.self, from: data)
    }
}


