//
//  ProfileSetupView.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var nickname = ""
    @State private var birthDate = Date()
    @State private var selectedGender = Gender.male
    
    private let maxDate = Calendar.current.date(byAdding: .year, value: -13, to: Date()) ?? Date()
    private let minDate = Calendar.current.date(byAdding: .year, value: -100, to: Date()) ?? Date()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 20) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Настройка профиля")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Расскажите о себе")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Никнейм")
                            .font(.headline)
                        
                        TextField("Введите никнейм", text: $nickname)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Дата рождения")
                            .font(.headline)
                        
                        DatePicker("Дата рождения", selection: $birthDate, in: minDate...maxDate, displayedComponents: .date)
                            .datePickerStyle(WheelDatePickerStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Пол")
                            .font(.headline)
                        
                        Picker("Пол", selection: $selectedGender) {
                            ForEach(Gender.allCases, id: \.self) { gender in
                                Text(genderDisplayName(gender)).tag(gender)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                
                Spacer()
                
                Button(action: {
                    Task {
                        await authViewModel.completeProfile(
                            nickname: nickname,
                            birthDate: birthDate,
                            gender: selectedGender
                        )
                    }
                }) {
                    HStack {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark")
                        }
                        Text("Сохранить профиль")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(nickname.isEmpty || authViewModel.isLoading)
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
    
    private func genderDisplayName(_ gender: Gender) -> String {
        switch gender {
        case .male:
            return "Мужской"
        case .female:
            return "Женский"
        case .other:
            return "Другой"
        }
    }
}

#Preview {
    ProfileSetupView()
        .environmentObject(AuthViewModel())
} 