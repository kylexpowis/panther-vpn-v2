//
//  Keychain.swift
//  PantherVPN
//
//  Created by Kyle Powis on 31/08/2025.
//


import Foundation
import Security

enum Keychain {
    @discardableResult
    static func setString(_ value: String, for key: String) throws -> Bool {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemDelete(query as CFDictionary) // replace if exists
        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecSuccess { return true }
        throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
    }

    static func getString(for key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var out: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &out)
        guard status == errSecSuccess, let data = out as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

enum Keys {
    static let devicePrivateKey = "wg_device_privkey"   // Value = the PrivateKey from [Interface]
    static let deviceAddressCIDR = "wg_device_address"  // Value = the Address from [Interface], e.g. "10.0.0.2/32"
}

