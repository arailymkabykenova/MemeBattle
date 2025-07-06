//
//  MainTabView.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var cardsViewModel: CardsViewModel
    @EnvironmentObject var roomViewModel: RoomViewModel
    @StateObject private var gameViewModel = GameViewModel()
    
    var body: some View {
        TabView {
            // Game Tab
            NavigationView {
                GameHomeView()
            }
            .tabItem {
                Image(systemName: "gamecontroller.fill")
                Text("Игра")
            }
            
            // Cards Tab
            NavigationView {
                CardsView()
            }
            .tabItem {
                Image(systemName: "rectangle.stack.fill")
                Text("Карты")
            }
            
            // Profile Tab
            NavigationView {
                ProfileView()
            }
            .tabItem {
                Image(systemName: "person.fill")
                Text("Профиль")
            }
        }
        .onAppear {
            // Load initial data
            Task {
                await cardsViewModel.loadMyCards()
                await roomViewModel.loadAvailableRooms()
            }
        }
    }
}

// MARK: - Game Home View

struct GameHomeView: View {
    @EnvironmentObject var roomViewModel: RoomViewModel
    @StateObject private var gameViewModel = GameViewModel()
    @State private var showingCreateRoom = false
    @State private var showingJoinRoom = false
    @State private var showingGame = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppConstants.largePadding) {
                // Header
                VStack(spacing: AppConstants.padding) {
                    Text("Meme War")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Найдите игру или создайте свою")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.top, AppConstants.largePadding)
                
                // Quick Actions
                VStack(spacing: AppConstants.padding) {
                    // Quick Match Button
                    Button(action: {
                        Task {
                            await roomViewModel.quickMatch()
                        }
                    }) {
                        HStack {
                            Image(systemName: "bolt.fill")
                            Text("Быстрый поиск")
                                .fontWeight(.medium)
                        }
                        .font(.body)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppConstants.padding)
                        .background(
                            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                                .fill(Color.blue)
                        )
                    }
                    .disabled(roomViewModel.isLoading)
                    
                    // Create Room Button
                    Button(action: {
                        showingCreateRoom = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Создать комнату")
                                .fontWeight(.medium)
                        }
                        .font(.body)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppConstants.padding)
                        .background(
                            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                                .fill(Color.green)
                        )
                    }
                    
                    // Join Room Button
                    Button(action: {
                        showingJoinRoom = true
                    }) {
                        HStack {
                            Image(systemName: "person.2.fill")
                            Text("Присоединиться к комнате")
                                .fontWeight(.medium)
                        }
                        .font(.body)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppConstants.padding)
                        .background(
                            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                                .fill(Color.orange)
                        )
                    }
                }
                .padding(.horizontal, AppConstants.largePadding)
                
                // Available Rooms
                if !roomViewModel.availableRooms.isEmpty {
                    VStack(alignment: .leading, spacing: AppConstants.padding) {
                        Text("Доступные комнаты")
                            .font(.headline)
                            .padding(.horizontal, AppConstants.largePadding)
                        
                        LazyVStack(spacing: AppConstants.padding) {
                            ForEach(roomViewModel.availableRooms) { room in
                                RoomCardView(room: room)
                            }
                        }
                        .padding(.horizontal, AppConstants.largePadding)
                    }
                }
                
                Spacer(minLength: 100)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingCreateRoom) {
            CreateRoomView()
        }
        .sheet(isPresented: $showingJoinRoom) {
            JoinRoomView()
        }
        .fullScreenCover(isPresented: $showingGame) {
            GameView()
                .environmentObject(gameViewModel)
        }
        .refreshable {
            await roomViewModel.loadAvailableRooms()
        }
        .onReceive(roomViewModel.$currentRoom) { room in
            if room != nil {
                showingGame = true
            }
        }
    }
}

// MARK: - Room Card View

struct RoomCardView: View {
    let room: RoomResponse
    @EnvironmentObject var roomViewModel: RoomViewModel
    
    var body: some View {
        Button(action: {
            Task {
                await roomViewModel.joinRoom(roomId: room.id)
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: AppConstants.smallPadding) {
                    Text(room.creator_nickname ?? "Неизвестно")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Image(systemName: "person.2.fill")
                        Text("\(room.current_players)/\(room.max_players)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let ageGroup = room.age_group {
                        Text("Возраст: \(ageGroup)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
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
        .environmentObject(AuthViewModel())
        .environmentObject(CardsViewModel())
        .environmentObject(RoomViewModel())
} 