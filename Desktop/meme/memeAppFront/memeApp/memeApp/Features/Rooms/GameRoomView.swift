import SwiftUI

struct GameRoomView: View {
    @ObservedObject var viewModel: GameRoomViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            AnimatedBackgroundView()
            VStack(spacing: 0) {
                HStack {
                    Text("Комната: \(viewModel.room.room_code ?? "N/A")")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.appTextPrimary)
                    Spacer()
                    Button(action: {
                        Task {
                            await viewModel.leaveRoom()
                            dismiss()
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.red)
                    }
                    .accessibilityLabel("Выйти из комнаты")
                }
                .padding([.top, .horizontal], Constants.UI.largePadding)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Статус:")
                            .font(.subheadline)
                            .foregroundColor(.appTextSecondary)
                        Text(viewModel.room.roomStatus.displayName)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    HStack {
                        Text("Возрастная группа:")
                            .font(.subheadline)
                            .foregroundColor(.appTextSecondary)
                        Text(viewModel.room.ageGroup.displayName)
                            .font(.subheadline)
                            .foregroundColor(.appTextPrimary)
                    }
                    HStack {
                        Text("Игроков:")
                            .font(.subheadline)
                            .foregroundColor(.appTextSecondary)
                        Text("\(viewModel.room.current_players)/\(viewModel.room.max_players)")
                            .font(.subheadline)
                            .foregroundColor(.appTextPrimary)
                    }
                }
                .padding(.horizontal, Constants.UI.largePadding)
                .padding(.top, 8)
                
                Text("Участники")
                    .font(.headline)
                    .foregroundColor(.appTextPrimary)
                    .padding(.top, 16)
                
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.room.participants ?? []) { participant in
                            HStack {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(participant.status == "active" ? .green : .gray)
                                Text(participant.user_nickname)
                                    .font(.body)
                                    .foregroundColor(.appTextPrimary)
                                Spacer()
                                Text(participant.participantStatus.displayName)
                                    .font(.caption)
                                    .foregroundColor(.appTextSecondary)
                            }
                            .padding(8)
                            .background(Color.appCardBackground)
                            .cornerRadius(12)
                            .glassmorphism()
                        }
                    }
                    .padding(.horizontal, Constants.UI.largePadding)
                }
                
                Spacer()
                
                if viewModel.room.creator_id == 1 { // мок: текущий пользователь - создатель
                    NavigationLink(destination: GameView(roomId: viewModel.room.id)) {
                        Text("Начать игру")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(Constants.UI.cornerRadius)
                            .shadow(color: .blue.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, Constants.UI.largePadding)
                    .padding(.bottom, 24)
                    .hapticFeedback(.medium)
                } else {
                    // Для обычных игроков показываем кнопку присоединиться к игре
                    NavigationLink(destination: GameView(roomId: viewModel.room.id)) {
                        Text("Присоединиться к игре")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(Constants.UI.cornerRadius)
                            .shadow(color: .blue.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, Constants.UI.largePadding)
                    .padding(.bottom, 24)
                    .hapticFeedback(.medium)
                }
            }
            if viewModel.isLoading {
                Color.black.opacity(0.2).ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(1.5)
            }
        }
        .navigationBarHidden(true)
        .alert("Ошибка", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
}

#Preview {
    GameRoomView(viewModel: GameRoomViewModel(room: Room(
        id: 1,
        creator_id: 1,
        max_players: 6,
        status: "waiting",
        room_code: "ABCD1",
        is_public: true,
        age_group: "teen",
        created_at: "2024-07-01T12:00:00Z",
        current_players: 2,
        participants: [
            RoomParticipant(id: 1, user_id: 1, user_nickname: "ТестовыйИгрок", joined_at: "2024-07-01T12:00:00Z", status: "active"),
            RoomParticipant(id: 2, user_id: 2, user_nickname: "Друг", joined_at: "2024-07-01T12:01:00Z", status: "active")
        ],
        creator_nickname: "ТестовыйИгрок",
        can_start_game: true
    )))
} 