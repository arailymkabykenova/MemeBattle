//
//  LoginViewModel.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import Foundation
import Combine

@MainActor
class LoginViewModel: BaseViewModel {
    private let authRepository: AuthRepositoryProtocol
    private let tokenManager = TokenManager.shared
    
    @Published var currentUser: UserResponse?
    @Published var isNewUser = false
    @Published var shouldShowProfileSetup = false
    
    init(authRepository: AuthRepositoryProtocol = AuthRepository()) {
        self.authRepository = authRepository
        super.init()
        
        // Subscribe to token manager changes
        addCancellable(tokenManager.$isAuthenticated.eraseToAnyPublisher()) { [weak self] isAuthenticated in
            if !isAuthenticated {
                self?.currentUser = nil
                self?.isNewUser = false
                self?.shouldShowProfileSetup = false
            }
        }
    }
    
    // MARK: - Authentication
    
    func authenticateDevice() async {
        let deviceId = getDeviceId()
        
        let result = await performAsyncTask {
            try await self.authRepository.deviceAuth(deviceId: deviceId)
        }
        
        if let authResponse = result {
            currentUser = authResponse.user
            isNewUser = authResponse.is_new_user
            
            if isNewUser {
                shouldShowProfileSetup = true
            }
        }
    }
    
    func getCurrentUser() async {
        let result = await performAsyncTask {
            try await self.authRepository.getCurrentUser()
        }
        
        if let user = result {
            currentUser = user
            isNewUser = !user.is_profile_complete
            shouldShowProfileSetup = isNewUser
        }
    }
    
    func logout() async {
        let _ = await performAsyncTask {
            try await self.authRepository.logout()
        }
        
        // Token manager will handle clearing the token
        currentUser = nil
        isNewUser = false
        shouldShowProfileSetup = false
    }
    
    // MARK: - Device ID
    
    private func getDeviceId() -> String {
        if let deviceId = UserDefaults.standard.string(forKey: "device_id") {
            return deviceId
        }
        
        let deviceId = UUID().uuidString
        UserDefaults.standard.set(deviceId, forKey: "device_id")
        return deviceId
    }
    
    // MARK: - State Management
    
    func resetState() {
        currentUser = nil
        isNewUser = false
        shouldShowProfileSetup = false
        clearError()
    }
    
    // MARK: - Computed Properties
    
    var isAuthenticated: Bool {
        return tokenManager.isAuthenticated && currentUser != nil
    }
    
    var userDisplayName: String {
        return currentUser?.displayName ?? "Гость"
    }
    
    var userRating: String {
        guard let user = currentUser else { return "0.0" }
        return formatRating(user.rating)
    }
    
    var userAge: String {
        return currentUser?.ageDisplay ?? "Не указан"
    }
    
    var userGender: String {
        return currentUser?.genderDisplay ?? "Не указан"
    }
    
    var profileCompletionStatus: String {
        guard let user = currentUser else { return "Не авторизован" }
        return user.is_profile_complete ? "Завершен" : "Не завершен"
    }
} 