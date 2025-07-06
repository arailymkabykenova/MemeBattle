//
//  ContentView.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var loginViewModel: LoginViewModel
    
    var body: some View {
        Group {
            if loginViewModel.isLoading {
                LoadingView("Авторизация...")
            } else if loginViewModel.showError {
                ErrorView(loginViewModel.errorMessage ?? "Неизвестная ошибка") {
                    Task {
                        await loginViewModel.authenticateDevice()
                    }
                }
            } else if loginViewModel.isAuthenticated {
                if loginViewModel.shouldShowProfileSetup {
                    ProfileSetupView()
                } else {
                    MainTabView()
                }
            } else {
                LoginView()
            }
        }
        .errorAlert(
            error: loginViewModel.errorMessage,
            isPresented: $loginViewModel.showError
        ) {
            Task {
                await loginViewModel.authenticateDevice()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LoginViewModel())
}
