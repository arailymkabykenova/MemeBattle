//
//  AuthViewModel.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import Foundation
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    private let authRepository: AuthRepositoryProtocol
    private let tokenManager: TokenManagerProtocol
    
    @Published var isAuthenticated = false
    @Published var isProfileComplete = false
    @Published var currentUser: UserResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init(authRepository: AuthRepositoryProtocol = AuthRepository(),
         tokenManager: TokenManagerProtocol = TokenManager.shared) {
        self.authRepository = authRepository
        self.tokenManager = tokenManager
        checkAuthStatus()
    }
    
    // MARK: - Authentication
    
    func checkAuthStatus() {
        guard let token = tokenManager.getToken() else {
            isAuthenticated = false
            isProfileComplete = false
            return
        }
        
        isAuthenticated = true
        loadCurrentUser()
    }
    
    func deviceAuth(deviceId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await authRepository.deviceAuth(deviceId: deviceId)
            currentUser = response.user
            isAuthenticated = true
            isProfileComplete = response.user.is_profile_complete
            
            if response.is_new_user {
                // New user needs to complete profile
                isProfileComplete = false
            }
        } catch {
            errorMessage = error.localizedDescription
            isAuthenticated = false
        }
        
        isLoading = false
    }
    
    func completeProfile(nickname: String, birthDate: Date, gender: Gender) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let request = UserProfileCreate(
                nickname: nickname,
                birth_date: birthDate,
                gender: gender
            )
            
            let user = try await authRepository.completeProfile(request: request)
            currentUser = user
            isProfileComplete = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func logout() async {
        isLoading = true
        
        do {
            try await authRepository.logout()
            isAuthenticated = false
            isProfileComplete = false
            currentUser = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    private func loadCurrentUser() {
        Task {
            do {
                let user = try await authRepository.getCurrentUser()
                currentUser = user
                isProfileComplete = user.is_profile_complete
            } catch {
                // If we can't load user, clear auth state
                isAuthenticated = false
                isProfileComplete = false
                currentUser = nil
            }
        }
    }
} 