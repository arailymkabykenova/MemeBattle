//
//  memeWarApp.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import SwiftUI

@main
struct memeWarApp: App {
    @StateObject private var loginViewModel = LoginViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(loginViewModel)
                .onAppear {
                    // Автоматическая авторизация при запуске
                    Task {
                        await loginViewModel.authenticateDevice()
                    }
                }
        }
    }
}
