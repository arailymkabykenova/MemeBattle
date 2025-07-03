import SwiftUI

struct RoomsView: View {
    @StateObject private var viewModel = RoomViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Анимированный фон
                AnimatedBackgroundView()
                
                VStack(spacing: 0) {
                    // Заголовок
                    HStack {
                        Text("Игровые комнаты")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.appTextPrimary)
                        Spacer()
                        Button(action: {
                            viewModel.showHelpSheet = true
                        }) {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding([.top, .horizontal], Constants.UI.largePadding)
                    
                    // Показываем текущую комнату пользователя
                    if let currentRoom = viewModel.currentRoom {
                        CurrentRoomCard(room: currentRoom) {
                            Task { await viewModel.leaveRoom(roomId: currentRoom.id) }
                        }
                        .padding(.horizontal, Constants.UI.largePadding)
                        .padding(.top, 16)
                    }
                    
                    if viewModel.isLoading {
                        Spacer()
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                .scaleEffect(1.5)
                            Text("Загрузка...")
                                .foregroundColor(.appTextSecondary)
                        }
                        Spacer()
                    } else if let error = viewModel.errorMessage {
                        Spacer()
                        ErrorView(message: error) {
                            Task { await viewModel.loadRooms() }
                        }
                        Spacer()
                    } else {
                        // Основные опции для игры
                        VStack(spacing: 24) {
                            // Быстрый поиск игры
                            QuickMatchCard {
                                Task { await viewModel.quickMatch() }
                            }
                            
                            // Присоединиться по коду
                            JoinByCodeCard {
                                viewModel.showJoinByCodeSheet = true
                            }
                            
                            // Создать комнату
                            CreateRoomCard {
                                viewModel.showCreateRoomSheet = true
                            }
                            
                            // Доступные комнаты
                            if !viewModel.rooms.isEmpty {
                                AvailableRoomsSection(rooms: viewModel.rooms) { room in
                                    Task { await viewModel.joinRoom(roomId: room.id) }
                                }
                            }
                        }
                        .padding(.horizontal, Constants.UI.largePadding)
                        .padding(.top, 24)
                        
                        Spacer()
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $viewModel.showCreateRoomSheet) {
                CreateRoomSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showJoinByCodeSheet) {
                JoinByCodeSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showHelpSheet) {
                RoomsHelpView()
            }
            .onAppear {
                Task { await viewModel.loadRooms() }
            }
            .alert("Ошибка", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }
}

// MARK: - Current Room Card
struct CurrentRoomCard: View {
    let room: Room
    let onLeave: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ваша комната")
                        .font(.headline)
                        .foregroundColor(.appTextPrimary)
                    
                    if let roomCode = room.room_code {
                        Text("Код: \(roomCode)")
                            .font(.subheadline)
                            .foregroundColor(.appTextSecondary)
                    }
                }
                
                Spacer()
                
                Button("Покинуть") {
                    onLeave()
                }
                .font(.caption)
                .foregroundColor(.red)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
            
            HStack {
                Label("\(room.current_players)/\(room.max_players) игроков", systemImage: "person.2.fill")
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
                
                Spacer()
                
                NavigationLink(destination: GameRoomView(viewModel: GameRoomViewModel(room: room))) {
                    Text("Открыть")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Quick Match Card
struct QuickMatchCard: View {
    let onQuickMatch: () -> Void
    
    var body: some View {
        Button(action: onQuickMatch) {
            HStack(spacing: 16) {
                Image(systemName: "bolt.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Быстрый поиск игры")
                        .font(.headline)
                        .foregroundColor(.appTextPrimary)
                    
                    Text("Найти игру за 30 секунд")
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.appTextSecondary)
            }
            .padding()
            .background(Color.yellow.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Join By Code Card
struct JoinByCodeCard: View {
    let onJoinByCode: () -> Void
    
    var body: some View {
        Button(action: onJoinByCode) {
            HStack(spacing: 16) {
                Image(systemName: "key.fill")
                    .font(.title2)
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Присоединиться по коду")
                        .font(.headline)
                        .foregroundColor(.appTextPrimary)
                    
                    Text("Ввести код комнаты друга")
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.appTextSecondary)
            }
            .padding()
            .background(Color.purple.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Create Room Card
struct CreateRoomCard: View {
    let onCreateRoom: () -> Void
    
    var body: some View {
        Button(action: onCreateRoom) {
            HStack(spacing: 16) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Создать комнату")
                        .font(.headline)
                        .foregroundColor(.appTextPrimary)
                    
                    Text("Создать новую игру")
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.appTextSecondary)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Available Rooms Section
struct AvailableRoomsSection: View {
    let rooms: [Room]
    let onJoinRoom: (Room) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Доступные комнаты")
                .font(.headline)
                .foregroundColor(.appTextPrimary)
            
            LazyVStack(spacing: 12) {
                ForEach(rooms) { room in
                    RoomCardView(room: room) {
                        onJoinRoom(room)
                    }
                }
            }
        }
    }
}

// MARK: - Error View
struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.red)
            
            Text(message)
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)
            
            Button("Повторить") {
                onRetry()
            }
            .foregroundColor(.blue)
        }
        .padding()
        .glassmorphism()
    }
}

// MARK: - Join By Code Sheet
struct JoinByCodeSheet: View {
    @ObservedObject var viewModel: RoomViewModel
    @State private var roomCode = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.purple)
                    
                    Text("Присоединиться к игре")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Введите код комнаты, который вам дал друг")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 12) {
                    TextField("Код комнаты", text: $roomCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textInputAutocapitalization(.characters)
                        .onChange(of: roomCode) { newValue in
                            roomCode = newValue.uppercased()
                        }
                    
                    Text("Пример: ABC123")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Присоединиться") {
                    Task {
                        await viewModel.joinRoomByCode(code: roomCode)
                        dismiss()
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.purple)
                .cornerRadius(12)
                .disabled(roomCode.isEmpty || viewModel.isLoading)
            }
            .padding()
            .navigationTitle("Присоединиться")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Room Card View (обновленный)
struct RoomCardView: View {
    let room: Room
    let onJoin: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(room.room_code ?? "N/A")
                    .font(.headline)
                    .foregroundColor(.appPrimaryColor)
                Spacer()
                Text(room.ageGroup.displayName)
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.appCardBackground.opacity(0.5))
                    .cornerRadius(8)
            }
            Text("Создатель: \(room.creator_nickname ?? "-")")
                .font(.subheadline)
                .foregroundColor(.appTextSecondary)
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.blue)
                Text("\(room.current_players)/\(room.max_players) игроков")
                    .font(.subheadline)
                    .foregroundColor(.appTextPrimary)
                Spacer()
                if room.canJoin {
                    Button(action: onJoin) {
                        Text("Войти")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.accentGradient)
                            .cornerRadius(12)
                            .shadow(color: .blue.opacity(0.2), radius: 6, x: 0, y: 3)
                    }
                    .hapticFeedback(.medium)
                } else {
                    Text(room.roomStatus.displayName)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(Constants.UI.largeCornerRadius)
        .glassmorphism()
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Create Room Sheet (обновленный)
struct CreateRoomSheet: View {
    @ObservedObject var viewModel: RoomViewModel
    @State private var selectedAgeGroup: AgeGroup = .teen
    @State private var isPublic: Bool = true
    @State private var maxPlayers: Int = 3
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Создать новую игру")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Настройте параметры комнаты")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Form {
                    Section(header: Text("Возрастная группа")) {
                        Picker("Группа", selection: $selectedAgeGroup) {
                            ForEach(AgeGroup.allCases, id: \.self) { group in
                                Text(group.displayName).tag(group)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    Section(header: Text("Публичность")) {
                        Toggle(isOn: $isPublic) {
                            VStack(alignment: .leading) {
                                Text(isPublic ? "Публичная" : "Приватная")
                                Text(isPublic ? "Другие игроки могут найти вашу комнату" : "Только по коду")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Section(header: Text("Максимум игроков")) {
                        Stepper(value: $maxPlayers, in: 3...8) {
                            HStack {
                                Text("\(maxPlayers) игроков")
                                Spacer()
                                Text("\(maxPlayers) 🎮")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Button("Создать комнату") {
                    Task {
                        await viewModel.createRoom(ageGroup: selectedAgeGroup, isPublic: isPublic, maxPlayers: maxPlayers)
                        dismiss()
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.blue)
                .cornerRadius(12)
                .padding(.horizontal)
                .disabled(viewModel.isLoading)
            }
            .navigationTitle("Создать комнату")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
        }
    }
}

// Универсальный неоновый эффект для любого View (если понадобится)
extension View {
    func neonShadow(color: Color = .blue, radius: CGFloat = 5) -> some View {
        self
            .shadow(color: color, radius: radius)
            .shadow(color: color.opacity(0.5), radius: radius * 2)
    }
}

#Preview {
    RoomsView()
} 
 