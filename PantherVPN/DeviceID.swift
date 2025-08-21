//
//  DeviceID.swift
//  PantherVPN
//
//  Created by Kyle Powis on 21/08/2025.
//

import Foundation
import Security

enum DeviceID {
    private static let key = "com.panthervpn.device-id"

    static func current() -> String {
        if let existing = read(key: key) { return existing }
        let id = UUID().uuidString
        _ = save(key: key, value: id)
        return id
    }

    @discardableResult
    private static func save(key: String, value: String) -> Bool {
        let data = Data(value.utf8)
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(q as CFDictionary)
        return SecItemAdd(q as CFDictionary, nil) == errSecSuccess
    }

    private static func read(key: String) -> String? {
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(q as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let str = String(data: data, encoding: .utf8) else { return nil }
        return str
    }
}
