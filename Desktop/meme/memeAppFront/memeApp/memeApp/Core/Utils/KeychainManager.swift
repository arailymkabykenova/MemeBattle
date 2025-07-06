import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()
    
    private init() {}
    
    // MARK: - Universal Methods
    
    func save(_ value: String, forKey key: String) throws {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Удаляем существующий элемент
        SecItemDelete(query as CFDictionary)
        
        // Добавляем новый элемент
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unableToSave
        }
    }
    
    func retrieve(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
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
    
    func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Legacy Token Methods (for backward compatibility)
    
    func saveToken(_ token: String) {
        try? save(token, forKey: "auth_token")
    }
    
    func getToken() -> String? {
        return retrieve(forKey: "auth_token")
    }
    
    func deleteToken() {
        delete(forKey: "auth_token")
    }
    
    func isTokenValid() -> Bool {
        return getToken() != nil
    }
}

enum KeychainError: Error {
    case unableToSave
    case unableToRetrieve
    case unableToDelete
} 