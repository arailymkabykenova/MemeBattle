//
//  DeviceAuthView.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import SwiftUI

struct DeviceAuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: AppConstants.largePadding) {
            Spacer()
            
            // App Logo/Title
            VStack(spacing: AppConstants.padding) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)
                
                Text("Meme War")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Карточная игра с мемами")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Auth Button
            Button(action: {
                Task {
                    await authViewModel.authenticateWithDevice()
                }
            }) {
                HStack {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "iphone")
                    }
                    
                    Text(authViewModel.isLoading ? "Подключение..." : "Войти в игру")
                        .fontWeight(.medium)
                }
                .font(.body)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppConstants.padding)
                .background(
                    RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                        .fill(Color.accentColor)
                )
            }
            .disabled(authViewModel.isLoading)
            .padding(.horizontal, AppConstants.largePadding)
            
            // Error Message
            if authViewModel.showError {
                Text(authViewModel.errorMessage ?? "Произошла ошибка")
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppConstants.largePadding)
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    DeviceAuthView()
        .environmentObject(AuthViewModel())
} 