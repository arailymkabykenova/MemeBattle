//
//  TokenManager.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import Foundation
import Combine

class TokenManager: ObservableObject {
    static let shared = TokenManager()
    
    private let keychainManager = KeychainManager.shared
    private let service = AppConstants.keychainService
    private let account = AppConstants.keychainAccount
    
    @Published var isAuthenticated = false
    @Published var currentToken: String?
    
    private init() {
        loadTokenFromKeychain()
    }
    
    // MARK: - Token Management
    
    func saveToken(_ token: String) {
        do {
            try keychainManager.saveString(token, service: service, account: account)
            currentToken = token
            isAuthenticated = true
        } catch {
            print("Error saving token: \(error)")
        }
    }
    
    func getToken() -> String? {
        return currentToken
    }
    
    func clearToken() {
        do {
            try keychainManager.delete(service: service, account: account)
            currentToken = nil
            isAuthenticated = false
        } catch {
            print("Error clearing token: \(error)")
        }
    }
    
    func updateToken(_ token: String) {
        do {
            try keychainManager.saveString(token, service: service, account: account)
            currentToken = token
            isAuthenticated = true
        } catch {
            print("Error updating token: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func loadTokenFromKeychain() {
        do {
            let token = try keychainManager.retrieveString(service: service, account: account)
            currentToken = token
            isAuthenticated = true
        } catch {
            currentToken = nil
            isAuthenticated = false
        }
    }
    
    // MARK: - Validation
    
    func isTokenValid() -> Bool {
        guard let token = currentToken, !token.isEmpty else {
            return false
        }
        
        // Здесь можно добавить дополнительную валидацию токена
        // например, проверку JWT expiration
        return true
    }
    
    func refreshTokenIfNeeded() async {
        // Здесь можно добавить логику обновления токена
        // если он истек
    }
} 