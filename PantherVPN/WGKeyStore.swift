//
//  WGKeyStore.swift
//  PantherVPN
//
//  Created by Kyle Powis on 02/09/2025.
//

import Foundation
import CryptoKit
import Security

enum PVKeychain {
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

enum WGKeyStore {
    private static let kPrivate = "pv.wg.device.privateKey"

    struct Pair {
        let priv: Data
        let pub: Data
        var privB64: String { priv.base64EncodedString() }
        var pubB64:  String { pub.base64EncodedString()  }
    }

    static func getOrCreate() throws -> Pair {
        if let priv = PVKeychain.get(kPrivate) {
            let privObj = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: priv)
            return .init(priv: priv, pub: privObj.publicKey.rawRepresentation)
        }
        let privObj = Curve25519.KeyAgreement.PrivateKey()
        let priv = privObj.rawRepresentation
        let pub  = privObj.publicKey.rawRepresentation
        _ = PVKeychain.set(priv, for: kPrivate)
        return .init(priv: priv, pub: pub)
    }

    static func publicKeyBase64() throws -> String  { try getOrCreate().pubB64 }
    static func privateKeyBase64() throws -> String { try getOrCreate().privB64 }
}


