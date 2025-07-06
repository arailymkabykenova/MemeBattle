//
//  TokenManager.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import Foundation
import Security

protocol TokenManagerProtocol {
    func saveToken(_ token: String)
    func getToken() -> String?
    func clearToken()
    func hasToken() -> Bool
}

class TokenManager: TokenManagerProtocol {
    static let shared = TokenManager()
    
    private let keychainManager = KeychainManager.shared
    private let tokenKey = "access_token"
    
    private init() {}
    
    // MARK: - Token Management
    
    func saveToken(_ token: String) {
        keychainManager.save(key: tokenKey, data: token)
    }
    
    func getToken() -> String? {
        return keychainManager.load(key: tokenKey)
    }
    
    func clearToken() {
        keychainManager.delete(key: tokenKey)
    }
    
    func hasToken() -> Bool {
        return getToken() != nil
    }
}

// MARK: - Keychain Manager

class KeychainManager {
    static let shared = KeychainManager()
    
    private let service = "com.memewar.app"
    
    private init() {}
    
    func save(key: String, data: String) {
        guard let data = data.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
    
    func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
} 