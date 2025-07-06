//
//  ProfileView.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var cardsViewModel: CardsViewModel
    @State private var showingEditProfile = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppConstants.largePadding) {
                // Profile Header
                ProfileHeaderView()
                
                // Stats Section
                StatsSectionView()
                
                // Actions Section
                ActionsSectionView()
                
                Spacer(minLength: 100)
            }
            .padding(AppConstants.largePadding)
        }
        .navigationTitle("Профиль")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
        }
        .onAppear {
            Task {
                await cardsViewModel.loadMyCards()
            }
        }
    }
}

// MARK: - Profile Header View

struct ProfileHeaderView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: AppConstants.padding) {
            // Avatar
            Circle()
                .fill(Color.accentColor.opacity(0.2))
                .frame(width: 100, height: 100)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.accentColor)
                )
            
            // User Info
            VStack(spacing: AppConstants.smallPadding) {
                Text(authViewModel.currentUser?.nickname ?? "Неизвестно")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let age = authViewModel.currentUser?.age {
                    Text("Возраст: \(age)")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                if let gender = authViewModel.currentUser?.gender {
                    Text("Пол: \(gender.displayName)")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                if let rating = authViewModel.currentUser?.rating {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", rating))
                            .font(.body)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding(AppConstants.largePadding)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Stats Section View

struct StatsSectionView: View {
    @EnvironmentObject var cardsViewModel: CardsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.padding) {
            Text("Статистика")
                .font(.headline)
                .fontWeight(.bold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AppConstants.padding), count: 2), spacing: AppConstants.padding) {
                StatCard(
                    title: "Всего карт",
                    value: "\(cardsViewModel.myCards.count)",
                    icon: "rectangle.stack.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Стартовые",
                    value: "\(cardsViewModel.starterCards.count)",
                    icon: "star.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "Обычные",
                    value: "\(cardsViewModel.myCards.filter { $0.card_type == .standard }.count)",
                    icon: "circle.fill",
                    color: .green
                )
                
                StatCard(
                    title: "Уникальные",
                    value: "\(cardsViewModel.myCards.filter { $0.card_type == .unique }.count)",
                    icon: "diamond.fill",
                    color: .purple
                )
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppConstants.smallPadding) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppConstants.padding)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - Actions Section View

struct ActionsSectionView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingEditProfile = false
    @State private var showingLogoutAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.padding) {
            Text("Действия")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: AppConstants.smallPadding) {
                ActionButton(
                    title: "Редактировать профиль",
                    icon: "pencil",
                    color: .blue
                ) {
                    showingEditProfile = true
                }
                
                ActionButton(
                    title: "Настройки",
                    icon: "gear",
                    color: .gray
                ) {
                    // TODO: Implement settings
                }
                
                ActionButton(
                    title: "Выйти",
                    icon: "rectangle.portrait.and.arrow.right",
                    color: .red
                ) {
                    showingLogoutAlert = true
                }
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
        }
        .alert("Выйти из аккаунта?", isPresented: $showingLogoutAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Выйти", role: .destructive) {
                authViewModel.logout()
            }
        } message: {
            Text("Вы уверены, что хотите выйти из аккаунта?")
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 20)
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(AppConstants.padding)
            .background(
                RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                    .fill(Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Edit Profile View

struct EditProfileView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Основная информация") {
                    TextField("Никнейм", text: $profileViewModel.nickname)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if let error = profileViewModel.nicknameError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    DatePicker(
                        "Дата рождения",
                        selection: $profileViewModel.birthDate,
                        displayedComponents: .date
                    )
                    
                    Picker("Пол", selection: $profileViewModel.selectedGender) {
                        ForEach(Gender.allCases, id: \.self) { gender in
                            Text(gender.displayName).tag(gender)
                        }
                    }
                }
            }
            .navigationTitle("Редактировать профиль")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        Task {
                            await profileViewModel.completeProfile()
                            dismiss()
                        }
                    }
                    .disabled(!profileViewModel.isFormValid || profileViewModel.isLoading)
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        ProfileView()
            .environmentObject(AuthViewModel())
            .environmentObject(CardsViewModel())
            .environmentObject(ProfileViewModel())
    }
} 