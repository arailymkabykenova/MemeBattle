//
//  ProfileViewModel.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import Foundation
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    private let authRepository: AuthRepositoryProtocol
    
    @Published var nickname = ""
    @Published var birthDate = Date()
    @Published var selectedGender: Gender = .other
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var nicknameError: String?
    @Published var isProfileComplete = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init(authRepository: AuthRepositoryProtocol = AuthRepository()) {
        self.authRepository = authRepository
    }
    
    // MARK: - Profile Management
    
    func completeProfile() async {
        guard isFormValid else { return }
        
        isLoading = true
        showError = false
        nicknameError = nil
        
        do {
            let request = UserProfileCreate(
                nickname: nickname.trimmingCharacters(in: .whitespacesAndNewlines),
                birth_date: birthDate,
                gender: selectedGender
            )
            
            let user = try await authRepository.completeProfile(request: request)
            isProfileComplete = true
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func checkProfileStatus() async {
        do {
            let user = try await authRepository.getCurrentUser()
            isProfileComplete = user.is_profile_complete
            
            if isProfileComplete {
                nickname = user.nickname ?? ""
                birthDate = user.birth_date ?? Date()
                selectedGender = user.gender ?? .other
            }
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - Validation
    
    var isFormValid: Bool {
        let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedNickname.isEmpty && 
               trimmedNickname.count >= 3 && 
               trimmedNickname.count <= 20 &&
               isValidNickname(trimmedNickname)
    }
    
    private func isValidNickname(_ nickname: String) -> Bool {
        // Only alphanumeric characters, underscores, and hyphens
        let nicknameRegex = "^[a-zA-Z0-9_-]+$"
        return nickname.range(of: nicknameRegex, options: .regularExpression) != nil
    }
    
    // MARK: - Private Methods
    
    private func handleError(_ error: Error) {
        showError = true
        
        if let networkError = error as? NetworkError {
            switch networkError {
            case .validationError(let message):
                if message.contains("nickname") {
                    nicknameError = "Никнейм уже занят или недопустим"
                } else {
                    errorMessage = message
                }
            default:
                errorMessage = networkError.localizedDescription
            }
        } else {
            errorMessage = error.localizedDescription
        }
    }
} 