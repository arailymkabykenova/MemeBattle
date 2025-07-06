//
//  GameState.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import Foundation

// MARK: - Game State Management

@MainActor
class GameState: ObservableObject {
    @Published var currentGame: GameResponse?
    @Published var currentRound: RoundResponse?
    @Published var players: [GamePlayerResponse] = []
    @Published var myCards: [CardResponse] = []
    @Published var roundChoices: [ChoiceResponse] = []
    @Published var roundVotes: [VoteResponse] = []
    @Published var timeRemaining: Int?
    @Published var isLoading = false
    @Published var error: String?
    
    // Game state
    @Published var gameStatus: GameStatus = .waiting
    @Published var roundStatus: RoundStatus = .waiting
    @Published var isMyTurn = false
    @Published var hasSubmittedChoice = false
    @Published var hasVoted = false
    
    // UI state
    @Published var showVotingView = false
    @Published var showGameFinished = false
    @Published var showTimeoutWarning = false
    
    private var gameTimer: Timer?
    private var roundTimer: Timer?
    
    init() {
        setupTimers()
    }
    
    deinit {
        // Note: Timers will be automatically invalidated when the object is deallocated
        // We can't call stopTimers() here due to actor isolation
    }
    
    // MARK: - State Updates
    
    func updateGameState(_ gameState: GameStateResponse) {
        currentGame = gameState.game
        currentRound = gameState.current_round
        players = gameState.players
        myCards = gameState.my_cards
        roundChoices = gameState.round_choices ?? []
        roundVotes = gameState.round_votes ?? []
        timeRemaining = gameState.time_remaining
        
        updateGameStatus()
    }
    
    func updateRoundState(_ round: RoundResponse) {
        currentRound = round
        roundStatus = round.status
        updateRoundStatus()
    }
    
    func addChoice(_ choice: ChoiceResponse) {
        roundChoices.append(choice)
        if choice.user_id == getCurrentUserId() {
            hasSubmittedChoice = true
        }
    }
    
    func addVote(_ vote: VoteResponse) {
        roundVotes.append(vote)
        if vote.voter_id == getCurrentUserId() {
            hasVoted = true
        }
    }
    
    func startVoting() {
        roundStatus = .voting
        showVotingView = true
        startRoundTimer()
    }
    
    func endRound() {
        roundStatus = .finished
        showVotingView = false
        stopRoundTimer()
    }
    
    func endGame() {
        gameStatus = .finished
        showGameFinished = true
        stopTimers()
    }
    
    // MARK: - Timer Management
    
    private func setupTimers() {
        // Setup game timer for overall game time
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateGameTimer()
        }
    }
    
    private func startRoundTimer() {
        roundTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateRoundTimer()
        }
    }
    
    private func stopRoundTimer() {
        roundTimer?.invalidate()
        roundTimer = nil
    }
    
    private func stopTimers() {
        gameTimer?.invalidate()
        gameTimer = nil
        stopRoundTimer()
    }
    
    private func updateGameTimer() {
        // Update game timer logic
        if let timeRemaining = timeRemaining, timeRemaining > 0 {
            self.timeRemaining = timeRemaining - 1
        }
    }
    
    private func updateRoundTimer() {
        // Update round timer logic
        if let timeRemaining = timeRemaining, timeRemaining > 0 {
            self.timeRemaining = timeRemaining - 1
            
            // Show timeout warning at 10 seconds
            if timeRemaining == 10 {
                showTimeoutWarning = true
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateGameStatus() {
        guard let game = currentGame else { return }
        gameStatus = game.status
    }
    
    private func updateRoundStatus() {
        guard let round = currentRound else { return }
        roundStatus = round.status
    }
    
    private func getCurrentUserId() -> Int {
        // This should be retrieved from UserDefaults or TokenManager
        // For now, return a placeholder
        return 0
    }
    
    // MARK: - Reset State
    
    func resetState() {
        currentGame = nil
        currentRound = nil
        players = []
        myCards = []
        roundChoices = []
        roundVotes = []
        timeRemaining = nil
        gameStatus = .waiting
        roundStatus = .waiting
        isMyTurn = false
        hasSubmittedChoice = false
        hasVoted = false
        showVotingView = false
        showGameFinished = false
        showTimeoutWarning = false
        error = nil
        stopTimers()
    }
}

// MARK: - Game State Extensions

extension GameState {
    var isGameActive: Bool {
        return currentGame != nil && gameStatus == .playing
    }
    
    var isRoundActive: Bool {
        return currentRound != nil && roundStatus == .collecting_choices
    }
    
    var isVotingActive: Bool {
        return currentRound != nil && roundStatus == .voting
    }
    
    var canSubmitChoice: Bool {
        return isRoundActive && !hasSubmittedChoice
    }
    
    var canVote: Bool {
        return isVotingActive && !hasVoted && roundChoices.count > 1
    }
    
    var currentPlayer: GamePlayerResponse? {
        let currentUserId = getCurrentUserId()
        return players.first { $0.id == currentUserId }
    }
    
    var otherPlayers: [GamePlayerResponse] {
        let currentUserId = getCurrentUserId()
        return players.filter { $0.id != currentUserId }
    }
    
    var availableChoices: [ChoiceResponse] {
        return roundChoices.filter { $0.user_id != getCurrentUserId() }
    }
}
