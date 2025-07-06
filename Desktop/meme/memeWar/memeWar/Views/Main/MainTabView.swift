//
//  MainTabView.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var loginViewModel: LoginViewModel
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Главная")
                }
            
            RoomsView()
                .tabItem {
                    Image(systemName: "gamecontroller.fill")
                    Text("Игра")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Профиль")
                }
        }
        .accentColor(.accentColor)
    }
}

// MARK: - Placeholder Views

struct HomeView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: AppConstants.largePadding) {
                Image(systemName: "house.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                
                Text("Добро пожаловать в Meme War!")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Здесь будет главная страница с новостями и статистикой")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppConstants.largePadding)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Главная")
        }
    }
}

struct RoomsView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: AppConstants.largePadding) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                
                Text("Игровые комнаты")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Здесь будут доступные комнаты для игры")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppConstants.largePadding)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Игра")
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var loginViewModel: LoginViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppConstants.largePadding) {
                    // Profile Header
                    VStack(spacing: AppConstants.padding) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.accentColor)
                        
                        Text(loginViewModel.userDisplayName)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Рейтинг: \(loginViewModel.userRating)")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, AppConstants.largePadding)
                    
                    // Profile Info
                    VStack(spacing: AppConstants.padding) {
                        ProfileInfoRow(title: "Возраст", value: loginViewModel.userAge)
                        ProfileInfoRow(title: "Пол", value: loginViewModel.userGender)
                        ProfileInfoRow(title: "Профиль", value: loginViewModel.profileCompletionStatus)
                    }
                    .padding(.horizontal, AppConstants.largePadding)
                    
                    // Logout Button
                    Button(action: {
                        Task {
                            await loginViewModel.logout()
                        }
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Выйти")
                                .fontWeight(.medium)
                        }
                        .font(.body)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppConstants.padding)
                        .background(
                            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                                .stroke(Color.red, lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, AppConstants.largePadding)
                    
                    Spacer(minLength: AppConstants.largePadding)
                }
            }
            .navigationTitle("Профиль")
        }
    }
}

struct ProfileInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, AppConstants.smallPadding)
        .padding(.horizontal, AppConstants.padding)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    MainTabView()
        .environmentObject(LoginViewModel())
} 