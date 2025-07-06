//
//  memeWarApp.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import SwiftUI

@main
struct memeWarApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var profileViewModel = ProfileViewModel()
    @StateObject private var cardsViewModel = CardsViewModel()
    @StateObject private var roomViewModel = RoomViewModel()
    @StateObject private var gameViewModel = GameViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(profileViewModel)
                .environmentObject(cardsViewModel)
                .environmentObject(roomViewModel)
                .environmentObject(gameViewModel)
        }
    }
}
