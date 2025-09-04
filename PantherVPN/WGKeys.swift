//
//  WGKeys.swift
//  PantherVPN
//
//  Created by Kyle Powis on 02/09/2025.
//
#if false
import Foundation
import CryptoKit

enum Keys {
    static let devicePrivateKey = "wg.device.privateKey"
}

enum Keychain {
    @discardableResult
    static func set(_ data: Data, for key: String) -> Bool {
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(q as CFDictionary)
        return SecItemAdd(q as CFDictionary, nil) == errSecSuccess
    }

    static func get(_ key: String) -> Data? {
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var out: CFTypeRef?
        SecItemCopyMatching(q as CFDictionary, &out)
        return out as? Data
    }
}

enum Base64 {
    static func enc(_ data: Data) -> String { data.base64EncodedString() }
}

enum WGKeys {
    struct KeyPair {
        let privateKeyRaw: Data
        let publicKeyRaw: Data
        var privateKeyBase64: String { Base64.enc(privateKeyRaw) }
        var publicKeyBase64: String  { Base64.enc(publicKeyRaw)  }
    }

    /// Creates or returns persisted device keypair (Curve25519). Private key stays in Keychain.
    static func getOrCreate() throws -> KeyPair {
        if let priv = Keychain.get(Keys.devicePrivateKey) {
            let privObj = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: priv)
            let pub = privObj.publicKey.rawRepresentation
            return .init(privateKeyRaw: priv, publicKeyRaw: pub)
        }
        let privObj = Curve25519.KeyAgreement.PrivateKey()
        let priv = privObj.rawRepresentation
        let pub  = privObj.publicKey.rawRepresentation
        _ = Keychain.set(priv, for: Keys.devicePrivateKey)
        return .init(privateKeyRaw: priv, publicKeyRaw: pub)
    }

    static func getOrCreatePublicKeyBase64() throws -> String {
        try getOrCreate().publicKeyBase64
    }

    static func getPrivateKeyBase64() throws -> String {
        try Base64.enc(getOrCreate().privateKeyRaw)
    }
}
#endif
