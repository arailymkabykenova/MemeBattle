//
//  GameViewModel.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import Foundation
import Combine
import UIKit

@MainActor
class GameViewModel: ObservableObject {
    private let gameRepository: GameRepositoryProtocol
    private let webSocketManager: WebSocketManager
    
    @Published var gameState: GameStateResponse?
    @Published var currentRound: RoundResponse?
    @Published var myCards: [CardResponse] = []
    @Published var roundChoices: [ChoiceResponse] = []
    @Published var roundVotes: [VoteResponse] = []
    @Published var players: [GamePlayerResponse] = []
    @Published var selectedCard: CardResponse?
    @Published var selectedVote: Int?
    @Published var isAnonymous = false
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var timeRemaining: Int?
    @Published var gameStatus: GameStatus = .waiting
    @Published var roundStatus: RoundStatus = .waiting
    
    private var cancellables = Set<AnyCancellable>()
    private var gameTimer: Timer?
    
    init(gameRepository: GameRepositoryProtocol = GameRepository(),
         webSocketManager: WebSocketManager = WebSocketManager.shared) {
        self.gameRepository = gameRepository
        self.webSocketManager = webSocketManager
        
        setupWebSocketObservers()
    }
    
    // MARK: - Game Management
    
    func loadGameState(roomId: Int) async {
        isLoading = true
        showError = false
        
        do {
            gameState = try await gameRepository.getGameState(roomId: roomId)
            updateGameState()
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func loadMyCards() async {
        do {
            myCards = try await gameRepository.getMyCardsForGame()
        } catch {
            handleError(error)
        }
    }
    
    func createRound(gameId: Int) async {
        isLoading = true
        showError = false
        
        do {
            currentRound = try await gameRepository.createRound(gameId: gameId)
            roundStatus = currentRound?.status ?? .waiting
            
            // Send round started message via WebSocket
            try await webSocketManager.sendMessage(WebSocketMessage.roundStarted(roundId: currentRound?.id ?? 0))
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func submitCardChoice() async {
        guard let roundId = currentRound?.id,
              let card = selectedCard else { return }
        
        isLoading = true
        showError = false
        
        do {
            let request = ChoiceRequest(
                card_id: card.id,
                is_anonymous: isAnonymous
            )
            
            let choice = try await gameRepository.submitChoice(roundId: roundId, request: request)
            
            // Send choice submitted message via WebSocket
            try await webSocketManager.submitCardChoice(
                roundId: roundId,
                cardId: card.id,
                isAnonymous: isAnonymous
            )
            
            selectedCard = nil
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func startVoting() async {
        guard let roundId = currentRound?.id else { return }
        
        isLoading = true
        showError = false
        
        do {
            try await gameRepository.startVoting(roundId: roundId)
            
            // Send voting started message via WebSocket
            try await webSocketManager.startVoting(roundId: roundId)
            
            roundStatus = .voting
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func submitVote() async {
        guard let roundId = currentRound?.id,
              let votedForUserId = selectedVote else { return }
        
        isLoading = true
        showError = false
        
        do {
            let request = VoteRequest(voted_for_user_id: votedForUserId)
            let vote = try await gameRepository.submitVote(roundId: roundId, request: request)
            
            // Send vote submitted message via WebSocket
            try await webSocketManager.submitVote(roundId: roundId, votedForUserId: votedForUserId)
            
            selectedVote = nil
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func loadRoundResults(roundId: Int) async {
        do {
            let results = try await gameRepository.getRoundResults(roundId: roundId)
            roundChoices = results.choices
            roundVotes = results.votes
        } catch {
            handleError(error)
        }
    }
    
    func endGame(gameId: Int) async {
        do {
            let game = try await gameRepository.endGame(gameId: gameId)
            gameStatus = game.status
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - Timer Management
    
    func startGameTimer() {
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTimer()
            }
        }
    }
    
    func stopGameTimer() {
        gameTimer?.invalidate()
        gameTimer = nil
    }
    
    private func updateTimer() {
        if let timeRemaining = timeRemaining, timeRemaining > 0 {
            self.timeRemaining = timeRemaining - 1
        } else {
            stopGameTimer()
        }
    }
    
    // MARK: - WebSocket Observers
    
    private func setupWebSocketObservers() {
        NotificationCenter.default.publisher(for: Notification.Name.roundStarted)
            .sink { [weak self] notification in
                Task { @MainActor in
                    await self?.handleRoundStarted(notification)
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name.votingStarted)
            .sink { [weak self] notification in
                Task { @MainActor in
                    await self?.handleVotingStarted(notification)
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name.roundEnded)
            .sink { [weak self] notification in
                Task { @MainActor in
                    await self?.handleRoundEnded(notification)
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name.gameEnded)
            .sink { [weak self] notification in
                Task { @MainActor in
                    await self?.handleGameEnded(notification)
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name.timeoutWarning)
            .sink { [weak self] notification in
                Task { @MainActor in
                    await self?.handleTimeoutWarning(notification)
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleRoundStarted(_ notification: Notification) async {
        // Handle round started event
        if let data = notification.userInfo?["data"] as? [String: Any],
           let roundId = data["round_id"] as? Int {
            await loadRoundResults(roundId: roundId)
        }
    }
    
    private func handleVotingStarted(_ notification: Notification) async {
        roundStatus = .voting
        startGameTimer()
    }
    
    private func handleRoundEnded(_ notification: Notification) async {
        roundStatus = .finished
        stopGameTimer()
        
        if let data = notification.userInfo?["data"] as? [String: Any],
           let roundId = data["round_id"] as? Int {
            await loadRoundResults(roundId: roundId)
        }
    }
    
    private func handleGameEnded(_ notification: Notification) async {
        gameStatus = .finished
        stopGameTimer()
    }
    
    private func handleTimeoutWarning(_ notification: Notification) async {
        // Handle timeout warning
        if let data = notification.userInfo?["data"] as? [String: Any],
           let timeRemaining = data["time_remaining"] as? Int {
            self.timeRemaining = timeRemaining
        }
    }
    
    // MARK: - Private Methods
    
    private func updateGameState() {
        guard let gameState = gameState else { return }
        
        currentRound = gameState.current_round
        myCards = gameState.my_cards
        players = gameState.players
        roundChoices = gameState.round_choices ?? []
        roundVotes = gameState.round_votes ?? []
        timeRemaining = gameState.time_remaining
        gameStatus = gameState.game.status
        roundStatus = currentRound?.status ?? .waiting
    }
    
    private func handleError(_ error: Error) {
        showError = true
        errorMessage = error.localizedDescription
    }
} 