//
//  ProfileViewModel.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import Foundation
import Combine

@MainActor
class ProfileSetupViewModel: BaseViewModel {
    private let authRepository: AuthRepositoryProtocol
    
    @Published var nickname = ""
    @Published var birthDate = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    @Published var gender = Gender.male
    
    @Published var nicknameError = ""
    @Published var birthDateError = ""
    @Published var genderError = ""
    
    @Published var profileSaved = false
    
    init(authRepository: AuthRepositoryProtocol = AuthRepository()) {
        self.authRepository = authRepository
        super.init()
        
        // Validate form on changes
        setupValidation()
    }
    
    // MARK: - Form Validation
    
    private func setupValidation() {
        // Nickname validation
        addCancellable(
            $nickname
                .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        ) { [weak self] nickname in
            self?.validateNicknameField(nickname)
        }
        
        // Birth date validation
        addCancellable($birthDate.eraseToAnyPublisher()) { [weak self] date in
            self?.validateBirthDate(date)
        }
        
        // Gender validation
        addCancellable($gender.eraseToAnyPublisher()) { [weak self] _ in
            self?.validateGender()
        }
    }
    
    private func validateNicknameField(_ nickname: String) {
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            nicknameError = "Никнейм не может быть пустым"
        } else if trimmed.count < 3 {
            nicknameError = "Никнейм должен содержать минимум 3 символа"
        } else if trimmed.count > 20 {
            nicknameError = "Никнейм не может быть длиннее 20 символов"
        } else if !trimmed.matches(pattern: "^[a-zA-Zа-яА-Я0-9_]+$") {
            nicknameError = "Никнейм может содержать только буквы, цифры и знак подчеркивания"
        } else {
            nicknameError = ""
        }
    }
    
    private func validateBirthDate(_ date: Date) {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: date, to: Date())
        let age = ageComponents.year ?? 0
        
        if age < 13 {
            birthDateError = "Вам должно быть не менее 13 лет"
        } else if age > 100 {
            birthDateError = "Пожалуйста, укажите корректную дату рождения"
        } else {
            birthDateError = ""
        }
    }
    
    private func validateGender() {
        genderError = ""
    }
    
    // MARK: - Form State
    
    var isFormValid: Bool {
        return nicknameError.isEmpty && 
               birthDateError.isEmpty && 
               genderError.isEmpty &&
               !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Profile Management
    
    func saveProfile() async {
        guard isFormValid else { return }
        
        let profile = UserProfileCreate(
            nickname: nickname.trimmingCharacters(in: .whitespacesAndNewlines),
            birth_date: birthDate,
            gender: gender
        )
        
        let result = await performAsyncTask {
            try await self.authRepository.completeProfile(profile: profile)
        }
        
        if result != nil {
            profileSaved = true
        }
    }
    
    // MARK: - Helper Methods
    
    func resetForm() {
        nickname = ""
        birthDate = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
        gender = Gender.male
        nicknameError = ""
        birthDateError = ""
        genderError = ""
        profileSaved = false
        clearError()
    }
}

// MARK: - String Extension for Validation

extension String {
    func matches(pattern: String) -> Bool {
        return self.range(of: pattern, options: .regularExpression) != nil
    }
} 