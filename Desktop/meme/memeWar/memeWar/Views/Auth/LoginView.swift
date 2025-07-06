//
//  LoginView.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var loginViewModel: LoginViewModel
    
    var body: some View {
        VStack(spacing: AppConstants.largePadding) {
            Spacer()
            
            // App Logo and Title
            VStack(spacing: AppConstants.padding) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)
                
                Text("Meme War")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Карточная игра с мемами")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Login Button
            Button(action: {
                Task {
                    await loginViewModel.authenticateDevice()
                }
            }) {
                HStack {
                    if loginViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "person.circle.fill")
                    }
                    
                    Text(loginViewModel.isLoading ? "Авторизация..." : "Войти в игру")
                        .fontWeight(.semibold)
                }
                .font(.body)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppConstants.padding)
                .background(
                    RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                        .fill(loginViewModel.isLoading ? Color.gray : Color.accentColor)
                )
            }
            .disabled(loginViewModel.isLoading)
            .padding(.horizontal, AppConstants.largePadding)
            
            // Info Text
            VStack(spacing: AppConstants.smallPadding) {
                Text("Автоматическая авторизация по устройству")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("Ваши данные защищены")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, AppConstants.largePadding)
            
            Spacer()
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color(.systemGray6)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

#Preview {
    LoginView()
        .environmentObject(LoginViewModel())
} 