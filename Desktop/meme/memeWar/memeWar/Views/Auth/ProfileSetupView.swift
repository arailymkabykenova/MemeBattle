//
//  ProfileSetupView.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject var loginViewModel: LoginViewModel
    @StateObject private var viewModel = ProfileSetupViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppConstants.largePadding) {
                    // Header
                    VStack(spacing: AppConstants.padding) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)
                        
                        Text("Настройка профиля")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Расскажите о себе, чтобы начать играть")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, AppConstants.largePadding)
                    
                    // Form
                    VStack(spacing: AppConstants.padding) {
                        // Nickname
                        VStack(alignment: .leading, spacing: AppConstants.smallPadding) {
                            Text("Никнейм")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Введите никнейм", text: $viewModel.nickname)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                            
                            if !viewModel.nicknameError.isEmpty {
                                Text(viewModel.nicknameError)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Birth Date
                        VStack(alignment: .leading, spacing: AppConstants.smallPadding) {
                            Text("Дата рождения")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            DatePicker(
                                "Дата рождения",
                                selection: $viewModel.birthDate,
                                in: ...Date(),
                                displayedComponents: .date
                            )
                            .datePickerStyle(CompactDatePickerStyle())
                            .labelsHidden()
                            
                            if !viewModel.birthDateError.isEmpty {
                                Text(viewModel.birthDateError)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Gender
                        VStack(alignment: .leading, spacing: AppConstants.smallPadding) {
                            Text("Пол")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Picker("Пол", selection: $viewModel.gender) {
                                ForEach(Gender.allCases, id: \.self) { gender in
                                    Text(gender.displayName).tag(gender)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            
                            if !viewModel.genderError.isEmpty {
                                Text(viewModel.genderError)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.horizontal, AppConstants.largePadding)
                    
                    // Save Button
                    Button(action: {
                        Task {
                            await viewModel.saveProfile()
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                            }
                            
                            Text(viewModel.isLoading ? "Сохранение..." : "Сохранить профиль")
                                .fontWeight(.semibold)
                        }
                        .font(.body)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppConstants.padding)
                        .background(
                            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                                .fill(viewModel.isFormValid && !viewModel.isLoading ? Color.accentColor : Color.gray)
                        )
                    }
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
                    .padding(.horizontal, AppConstants.largePadding)
                    
                    Spacer(minLength: AppConstants.largePadding)
                }
            }
            .navigationBarHidden(true)
        }
        .onReceive(viewModel.$profileSaved) { saved in
            if saved {
                // Profile saved successfully, update login view model
                Task {
                    await loginViewModel.getCurrentUser()
                }
            }
        }
        .errorAlert(
            error: viewModel.errorMessage,
            isPresented: $viewModel.showError
        ) {
            Task {
                await viewModel.saveProfile()
            }
        }
    }
}

#Preview {
    ProfileSetupView()
        .environmentObject(LoginViewModel())
} 