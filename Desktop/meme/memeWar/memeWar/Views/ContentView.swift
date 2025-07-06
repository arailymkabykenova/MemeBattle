//
//  ContentView.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var cardsViewModel: CardsViewModel
    
    var body: some View {
        Group {
            if authViewModel.isLoading {
                LoadingView()
            } else if !authViewModel.isAuthenticated {
                // Step 1: Device Authentication
                DeviceAuthView()
            } else if !profileViewModel.isProfileComplete {
                // Step 2: Profile Completion
                ProfileSetupView()
            } else if !cardsViewModel.hasStarterCards {
                // Step 3: Get Starter Cards
                StarterCardsView()
            } else {
                // Step 4: Main App with Tab Bar
                MainTabView()
            }
        }
        .onAppear {
            Task {
                await authViewModel.checkAuthStatus()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
        .environmentObject(ProfileViewModel())
        .environmentObject(CardsViewModel())
} 