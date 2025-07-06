//
//  ProfileSetupView.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var cardsViewModel: CardsViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppConstants.largePadding) {
                    // Header
                    VStack(spacing: AppConstants.padding) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)
                        
                        Text("Завершите профиль")
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("Расскажите о себе, чтобы начать играть")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, AppConstants.largePadding)
                    
                    // Form
                    VStack(spacing: AppConstants.largePadding) {
                        // Nickname Field
                        VStack(alignment: .leading, spacing: AppConstants.smallPadding) {
                            Text("Никнейм")
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            TextField("Введите никнейм", text: $profileViewModel.nickname)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                            
                            if let error = profileViewModel.nicknameError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Birth Date Field
                        VStack(alignment: .leading, spacing: AppConstants.smallPadding) {
                            Text("Дата рождения")
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            DatePicker(
                                "Дата рождения",
                                selection: $profileViewModel.birthDate,
                                in: ...Date(),
                                displayedComponents: .date
                            )
                            .datePickerStyle(WheelDatePickerStyle())
                            .labelsHidden()
                        }
                        
                        // Gender Field
                        VStack(alignment: .leading, spacing: AppConstants.smallPadding) {
                            Text("Пол")
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            Picker("Пол", selection: $profileViewModel.selectedGender) {
                                ForEach(Gender.allCases, id: \.self) { gender in
                                    Text(gender.displayName).tag(gender)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                    }
                    .padding(.horizontal, AppConstants.largePadding)
                    
                    Spacer()
                    
                    // Submit Button
                    Button(action: {
                        Task {
                            await profileViewModel.completeProfile()
                        }
                    }) {
                        HStack {
                            if profileViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                            }
                            
                            Text(profileViewModel.isLoading ? "Сохранение..." : "Завершить профиль")
                                .fontWeight(.medium)
                        }
                        .font(.body)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppConstants.padding)
                        .background(
                            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                                .fill(isFormValid ? Color.accentColor : Color.gray)
                        )
                    }
                    .disabled(!isFormValid || profileViewModel.isLoading)
                    .padding(.horizontal, AppConstants.largePadding)
                    
                    // Error Message
                    if profileViewModel.showError {
                        Text(profileViewModel.errorMessage ?? "Произошла ошибка")
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppConstants.largePadding)
                    }
                    
                    Spacer(minLength: 100)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                Task {
                    await profileViewModel.checkProfileStatus()
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        profileViewModel.isFormValid
    }
}

#Preview {
    ProfileSetupView()
        .environmentObject(ProfileViewModel())
        .environmentObject(CardsViewModel())
} 