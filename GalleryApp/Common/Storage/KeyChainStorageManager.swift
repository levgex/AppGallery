//
//  KeyChainStorageManager.swift
//  GalleryApp
//
//  Created by evgeniy.lebedev on 01.11.2024.
//

import Foundation

class KeyChainStorageManager {

    static let apiKeyKeychainKey = "apiKeyKeychainKey"

    static func saveStringValue(_ value: String, forKey key: String, completion: ((Bool) -> Void)? = nil) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let data = value.data(using: .utf8) else {
                completion?(false)
                return
            }
            self.delete(forKey: key)

            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
                kSecValueData as String: data
            ]

            let status = SecItemAdd(addQuery as CFDictionary, nil)
            completion?(status == errSecSuccess)
        }
    }

    static func getStringValue(forKey key: String, completion: @escaping (String?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
                kSecReturnData as String: true
            ]

            var item: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &item)

            var result: String? = nil
            if status == errSecSuccess, let data = item as? Data {
                result = String(data: data, encoding: .utf8)
            }
            completion(result)
        }
    }

    static func delete(forKey key: String, completion: ((Bool) -> Void)? = nil) {
        DispatchQueue.global(qos: .userInitiated).async {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key
            ]

            let status = SecItemDelete(query as CFDictionary)
            completion?(status == errSecSuccess)
        }
    }
}
