//
//  GameView.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import SwiftUI

struct GameView: View {
    @EnvironmentObject var gameViewModel: GameViewModel
    @EnvironmentObject var roomViewModel: RoomViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppConstants.padding) {
                // Game Header
                GameHeaderView()
                
                // Main Game Area
                if gameViewModel.isLoading {
                    Spacer()
                    LoadingView("Загрузка игры...")
                    Spacer()
                } else if let game = gameViewModel.currentGame {
                    switch game.status {
                    case .waiting:
                        WaitingForPlayersView()
                    case .playing:
                        PlayingGameView()
                    case .finished:
                        GameFinishedView()
                    }
                } else {
                    Spacer()
                    Text("Игра не найдена")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .padding()
            .navigationTitle("Игра")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Выйти") {
                        Task {
                            await roomViewModel.leaveRoom()
                            dismiss()
                        }
                    }
                }
            }
        }
        .onAppear {
            if let roomId = roomViewModel.currentRoom?.id {
                Task {
                    await gameViewModel.loadGameState(roomId: roomId)
                }
            }
        }
    }
}

// MARK: - Game Header View

struct GameHeaderView: View {
    @EnvironmentObject var gameViewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: AppConstants.smallPadding) {
            if let game = gameViewModel.currentGame {
                HStack {
                    Text("Раунд \(game.current_round ?? 0)/\(game.total_rounds)")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    if gameViewModel.timeRemaining > 0 {
                        Text(formatTime(gameViewModel.timeRemaining))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                }
                
                HStack {
                    Text("Игроков: \(game.participants.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(game.status.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, AppConstants.smallPadding)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(statusColor(game.status).opacity(0.2))
                        )
                        .foregroundColor(statusColor(game.status))
                }
            }
        }
        .padding(AppConstants.padding)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                .fill(Color(.systemGray6))
        )
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    private func statusColor(_ status: GameStatus) -> Color {
        switch status {
        case .waiting:
            return .blue
        case .playing:
            return .green
        case .finished:
            return .gray
        }
    }
}

// MARK: - Waiting For Players View

struct WaitingForPlayersView: View {
    @EnvironmentObject var gameViewModel: GameViewModel
    @EnvironmentObject var roomViewModel: RoomViewModel
    
    var body: some View {
        VStack(spacing: AppConstants.largePadding) {
            Spacer()
            
            VStack(spacing: AppConstants.padding) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Ожидание игроков")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Минимум 2 игрока для начала игры")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let game = gameViewModel.currentGame {
                VStack(spacing: AppConstants.padding) {
                    Text("Игроки (\(game.participants.count)/\(game.participants.count))")
                        .font(.headline)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: AppConstants.padding) {
                        ForEach(game.participants) { participant in
                            PlayerCardView(participant: participant)
                        }
                    }
                }
            }
            
            Spacer()
            
            if let room = roomViewModel.currentRoom, room.creator_id == roomViewModel.myRoom?.room.creator_id {
                Button(action: {
                    Task {
                        await roomViewModel.startGame()
                    }
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Начать игру")
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
                .disabled(gameViewModel.currentGame?.participants.count ?? 0 < 2)
            }
        }
    }
}

// MARK: - Playing Game View

struct PlayingGameView: View {
    @EnvironmentObject var gameViewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: AppConstants.largePadding) {
            // Situation Display
            SituationView()
            
            // Game Phase
            if gameViewModel.canSubmitChoice {
                CardSelectionView()
            } else if gameViewModel.canVote {
                VotingView()
            } else {
                WaitingForPhaseView()
            }
        }
    }
}

// MARK: - Situation View

struct SituationView: View {
    @EnvironmentObject var gameViewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: AppConstants.padding) {
            Text("Ситуация")
                .font(.headline)
                .fontWeight(.bold)
            
            Text(gameViewModel.situation.isEmpty ? "Загрузка ситуации..." : gameViewModel.situation)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(AppConstants.padding)
                .background(
                    RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                        .fill(Color(.systemGray6))
                )
        }
    }
}

// MARK: - Card Selection View

struct CardSelectionView: View {
    @EnvironmentObject var gameViewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: AppConstants.largePadding) {
            Text("Выберите карту")
                .font(.title2)
                .fontWeight(.bold)
            
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AppConstants.padding), count: 2), spacing: AppConstants.padding) {
                    ForEach(gameViewModel.myCards) { card in
                        GameCardView(
                            card: card,
                            isSelected: gameViewModel.selectedCard?.id == card.id
                        ) {
                            gameViewModel.selectCard(card)
                        }
                    }
                }
                .padding(.horizontal, AppConstants.padding)
            }
            
            Button(action: {
                Task {
                    await gameViewModel.submitCardChoice()
                }
            }) {
                HStack {
                    if gameViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    
                    Text(gameViewModel.isLoading ? "Отправка..." : "Отправить выбор")
                        .fontWeight(.medium)
                }
                .font(.body)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppConstants.padding)
                .background(
                    RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                        .fill(gameViewModel.selectedCard != nil ? Color.accentColor : Color.gray)
                )
            }
            .disabled(gameViewModel.selectedCard == nil || gameViewModel.isLoading)
        }
    }
}

// MARK: - Voting View

struct VotingView: View {
    @EnvironmentObject var gameViewModel: GameViewModel
    @State private var selectedChoice: RoundChoiceResponse?
    
    var body: some View {
        VStack(spacing: AppConstants.largePadding) {
            Text("Голосуйте за лучшую карту")
                .font(.title2)
                .fontWeight(.bold)
            
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AppConstants.padding), count: 2), spacing: AppConstants.padding) {
                    ForEach(gameViewModel.choicesForVoting) { choice in
                        VoteCardView(
                            choice: choice,
                            isSelected: selectedChoice?.id == choice.id
                        ) {
                            selectedChoice = choice
                        }
                    }
                }
                .padding(.horizontal, AppConstants.padding)
            }
            
            Button(action: {
                if let choice = selectedChoice {
                    Task {
                        await gameViewModel.submitVote(votedForId: choice.user_id)
                    }
                }
            }) {
                HStack {
                    if gameViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    
                    Text(gameViewModel.isLoading ? "Отправка..." : "Проголосовать")
                        .fontWeight(.medium)
                }
                .font(.body)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppConstants.padding)
                .background(
                    RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                        .fill(selectedChoice != nil ? Color.accentColor : Color.gray)
                )
            }
            .disabled(selectedChoice == nil || gameViewModel.isLoading)
        }
        .onAppear {
            if let round = gameViewModel.currentRound {
                Task {
                    await gameViewModel.loadChoicesForVoting(roundId: round.id)
                }
            }
        }
    }
}

// MARK: - Waiting For Phase View

struct WaitingForPhaseView: View {
    var body: some View {
        VStack(spacing: AppConstants.largePadding) {
            Spacer()
            
            VStack(spacing: AppConstants.padding) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                    .scaleEffect(1.5)
                
                Text("Ожидание других игроков...")
                    .font(.title3)
                    .fontWeight(.medium)
                
                Text("Пожалуйста, подождите пока все игроки сделают свой выбор")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
    }
}

// MARK: - Game Finished View

struct GameFinishedView: View {
    @EnvironmentObject var gameViewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: AppConstants.largePadding) {
            Spacer()
            
            VStack(spacing: AppConstants.padding) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                
                Text("Игра завершена!")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let game = gameViewModel.currentGame,
                   let winnerId = game.winner_id,
                   let winner = game.participants.first(where: { $0.user_id == winnerId }) {
                    Text("Победитель: \(winner.user_nickname)")
                        .font(.headline)
                        .foregroundColor(.green)
                }
            }
            
            if let results = gameViewModel.roundResults {
                VStack(spacing: AppConstants.padding) {
                    Text("Финальные результаты")
                        .font(.headline)
                    
                    ForEach(results.scores, id: \.user_id) { score in
                        HStack {
                            Text(score.user_nickname)
                            Spacer()
                            Text("\(score.score)")
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal, AppConstants.padding)
                        .padding(.vertical, AppConstants.smallPadding)
                        .background(
                            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                                .fill(Color(.systemGray6))
                        )
                    }
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Helper Views

struct PlayerCardView: View {
    let participant: GameParticipantResponse
    
    var body: some View {
        VStack(spacing: AppConstants.smallPadding) {
            Circle()
                .fill(Color.accentColor.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.accentColor)
                )
            
            Text(participant.user_nickname)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
            
            Text("\(participant.score)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(AppConstants.smallPadding)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

struct GameCardView: View {
    let card: CardResponse
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: AppConstants.smallPadding) {
                AsyncImage(url: URL(string: card.image_url)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            ProgressView()
                        )
                }
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadius))
                
                Text(card.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .padding(AppConstants.smallPadding)
            .background(
                RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct VoteCardView: View {
    let choice: RoundChoiceResponse
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: AppConstants.smallPadding) {
                AsyncImage(url: URL(string: choice.card_image_url)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            ProgressView()
                        )
                }
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadius))
                
                VStack(spacing: 2) {
                    Text(choice.card_name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text("от \(choice.user_nickname)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(AppConstants.smallPadding)
            .background(
                RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    GameView()
        .environmentObject(GameViewModel())
        .environmentObject(RoomViewModel())
} 