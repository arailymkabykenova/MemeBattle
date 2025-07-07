//
//  MainTabView.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var roomViewModel = RoomViewModel()
    @StateObject private var cardsViewModel = CardsViewModel()
    
    var body: some View {
        TabView {
            // Game Tab
            NavigationView {
                GameView()
                    .environmentObject(roomViewModel)
            }
            .tabItem {
                Image(systemName: "gamecontroller.fill")
                Text("Игра")
            }
            
            // Cards Tab
            NavigationView {
                CardsView()
                    .environmentObject(cardsViewModel)
            }
            .tabItem {
                Image(systemName: "rectangle.stack.fill")
                Text("Карты")
            }
            
            // Profile Tab
            NavigationView {
                ProfileView()
                    .environmentObject(authViewModel)
            }
            .tabItem {
                Image(systemName: "person.fill")
                Text("Профиль")
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
} 