//
//  ContentView.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        Group {
            if authViewModel.isLoading {
                LoadingView()
            } else if !authViewModel.isAuthenticated {
                DeviceAuthView()
                    .environmentObject(authViewModel)
            } else if !authViewModel.isProfileComplete {
                ProfileSetupView()
                    .environmentObject(authViewModel)
            } else {
                MainTabView()
                    .environmentObject(authViewModel)
            }
        }
        .alert("Ошибка", isPresented: .constant(authViewModel.errorMessage != nil)) {
            Button("OK") {
                authViewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

#Preview {
    ContentView()
} 