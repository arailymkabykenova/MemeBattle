import SwiftUI

struct GameView: View {
    @StateObject private var viewModel: GameViewModel
    let roomId: Int
    
    init(roomId: Int) {
        self.roomId = roomId
        self._viewModel = StateObject(wrappedValue: GameViewModel())
    }
    
    var body: some View {
        ZStack {
            // Анимированный фон
            AnimatedBackgroundView()
            
            VStack {
                // Заголовок с информацией о комнате
                GameHeaderView(viewModel: viewModel)
                
                // Основной контент в зависимости от состояния игры
                switch viewModel.gameState {
                case .waiting:
                    GameWaitingView(viewModel: viewModel)
                case .choosing:
                    GameChoosingView(viewModel: viewModel)
                case .voting:
                    GameVotingView(viewModel: viewModel)
                case .roundEnd:
                    GameRoundEndView(viewModel: viewModel)
                case .gameEnd:
                    GameEndView(viewModel: viewModel)
                case .error:
                    GameErrorView(viewModel: viewModel)
                }
            }
            .padding()
        }
        .onAppear {
            Task {
                await viewModel.joinGame(roomId: roomId)
            }
        }
        .onDisappear {
            Task {
                await viewModel.leaveGame()
            }
        }
        .alert("Ошибка", isPresented: .constant(!viewModel.errorMessage.isEmpty)) {
            Button("OK") {
                viewModel.errorMessage = ""
            }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

// MARK: - Game Header View
struct GameHeaderView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Комната #\(viewModel.currentGame?.room_id ?? 0)")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let game = viewModel.currentGame {
                        Text("Игроков: \(game.players.count)/\(game.total_rounds)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Таймер
                if viewModel.timeRemaining > 0 {
                    TimerView(timeRemaining: viewModel.timeRemaining)
                }
                
                // Кнопка выхода
                Button(action: {
                    Task {
                        await viewModel.leaveGame()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }
            }
            
            // Прогресс игры
            if let game = viewModel.currentGame {
                ProgressView(value: Double(game.current_round ?? 0), total: Double(game.total_rounds))
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

// MARK: - Timer View
struct TimerView: View {
    let timeRemaining: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.caption)
            
            Text("\(timeRemaining)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(timeRemaining <= 10 ? .red : .primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
}

// MARK: - Game Waiting View
struct GameWaitingView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Ожидание игроков")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if let game = viewModel.currentGame {
                    Text("\(game.players.count) из \(game.total_rounds) игроков готовы")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    // Список игроков
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(game.players) { player in
                            PlayerCardView(player: player)
                        }
                    }
                    .padding(.top)
                }
            }
            
            Spacer()
            
            // Кнопка начала игры (только для создателя)
            if let game = viewModel.currentGame, game.players.count >= 2 {
                Button(action: {
                    Task {
                        await viewModel.startGame()
                    }
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Начать игру")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .disabled(viewModel.isLoading)
            }
        }
        .padding()
    }
}

// MARK: - Player Card View
struct PlayerCardView: View {
    let player: GamePlayer
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(player.nickname.prefix(1)))
                        .font(.headline)
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading) {
                Text(player.nickname)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text("Счет: \(player.score)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if player.is_ready {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
}

// MARK: - Game Choosing View
struct GameChoosingView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Ситуация
            if let round = viewModel.currentRound {
                VStack(spacing: 12) {
                    Text("Ситуация")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(round.situation)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                }
            }
            
            // Карты игрока
            VStack(spacing: 12) {
                Text("Выберите карту")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(viewModel.myCards) { card in
                        GameCardView(card: card) {
                            Task {
                                await viewModel.playCard(card)
                            }
                        }
                    }
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Game Card View
struct GameCardView: View {
    let card: UserCardResponse
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                AsyncImage(url: URL(string: card.image_url)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
                .frame(height: 120)
                .cornerRadius(8)
                
                Text(card.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Game Voting View
struct GameVotingView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Голосуйте за лучший ответ!")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ForEach(viewModel.roundChoices) { choice in
                    VoteCardView(choice: choice) {
                        Task {
                            await viewModel.submitVote(for: choice)
                        }
                    }
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Vote Card View
struct VoteCardView: View {
    let choice: RoundChoice
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                AsyncImage(url: URL(string: choice.card_image_url)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
                .frame(height: 120)
                .cornerRadius(8)
                
                Text(choice.card_name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Game Round End View
struct GameRoundEndView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "star.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                
                Text("Раунд завершен!")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if let round = viewModel.currentRound, let winnerId = round.winner_id {
                    Text("Победитель: Игрок #\(winnerId)")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Game End View
struct GameEndView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                
                Text("Игра завершена!")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if let game = viewModel.currentGame, let winnerId = game.winner_id {
                    Text("Победитель: Игрок #\(winnerId)")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button("Вернуться в меню") {
                // Навигация обратно
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(12)
        }
        .padding()
    }
}

// MARK: - Game Error View
struct GameErrorView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                
                Text("Ошибка")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(viewModel.errorMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            Button("Попробовать снова") {
                // Попытка переподключения
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(12)
        }
        .padding()
    }
}

#Preview {
    GameView(roomId: 1)
} 