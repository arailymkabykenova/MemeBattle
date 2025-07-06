//
//  AuthViewModel.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import Foundation
import Combine
import UIKit

@MainActor
class AuthViewModel: ObservableObject {
    private let authRepository: AuthRepositoryProtocol
    private let tokenManager: TokenManagerProtocol
    
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var currentUser: UserResponse?
    @Published var isNewUser = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init(authRepository: AuthRepositoryProtocol = AuthRepository(),
         tokenManager: TokenManagerProtocol = TokenManager.shared) {
        self.authRepository = authRepository
        self.tokenManager = tokenManager
        
        // Check authentication status on init
        checkAuthenticationStatus()
    }
    
    // MARK: - Authentication
    
    func authenticate() async {
        isLoading = true
        showError = false
        
        do {
            let deviceId = getDeviceId()
            let authResponse = try await authRepository.deviceAuth(deviceId: deviceId)
            
            currentUser = authResponse.user
            isNewUser = authResponse.is_new_user
            isAuthenticated = true
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func logout() async {
        isLoading = true
        
        do {
            try await authRepository.logout()
            isAuthenticated = false
            currentUser = nil
            isNewUser = false
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func getCurrentUser() async {
        do {
            currentUser = try await authRepository.getCurrentUser()
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - Private Methods
    
    private func checkAuthenticationStatus() {
        if let token = tokenManager.getToken(), !token.isEmpty {
            isAuthenticated = true
            Task {
                await getCurrentUser()
            }
        } else {
            isAuthenticated = false
        }
    }
    
    private func getDeviceId() -> String {
        if let deviceId = UIDevice.current.identifierForVendor?.uuidString {
            return deviceId
        }
        
        // Fallback to UserDefaults if device ID is not available
        if let savedDeviceId = UserDefaults.standard.string(forKey: "device_id") {
            return savedDeviceId
        }
        
        let newDeviceId = UUID().uuidString
        UserDefaults.standard.set(newDeviceId, forKey: "device_id")
        return newDeviceId
    }
    
    private func handleError(_ error: Error) {
        showError = true
        errorMessage = error.localizedDescription
    }
} 