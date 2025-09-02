//
//  KeypairManager.swift
//  PantherVPN
//
//  Created by Kyle Powis on 31/08/2025.
//

import CryptoKit

enum WGKeys {
    static func getOrCreatePublicKeyBase64() throws -> String {
        if let priv = Keychain.getString(for: Keys.devicePrivateKey), !priv.isEmpty {
            // Derive pub from stored priv if you want (optional). For simplicity we just keep pub in UserDefaults.
            if let pub = UserDefaults.standard.string(forKey: "wg_device_pubkey") { return pub }
        }

        // Generate new X25519 keypair
        let priv = Curve25519.KeyAgreement.PrivateKey()
        let privBase64 = priv.rawRepresentation.base64EncodedString()
        let pubBase64 = priv.publicKey.rawRepresentation.base64EncodedString()

        // Persist
        try Keychain.setString(privBase64, for: Keys.devicePrivateKey)
        UserDefaults.standard.set(pubBase64, forKey: "wg_device_pubkey")

        return pubBase64
    }

    static func devicePrivateKeyBase64() -> String? {
        Keychain.getString(for: Keys.devicePrivateKey)
    }
}
