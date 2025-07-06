//
//  GameViewModel.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import Foundation
import Combine

@MainActor
class GameViewModel: BaseViewModel {
    private let gameRepository: GameRepositoryProtocol
    private let cardsRepository: CardsRepositoryProtocol
    private let webSocketManager = WebSocketManager.shared
    
    @Published var currentGame: GameDetailResponse?
    @Published var gameState: GameState?
    @Published var myCards: [CardResponse] = []
    @Published var currentRound: RoundResponse?
    @Published var roundChoices: [CardChoiceResponse] = []
    @Published var roundVotes: [VoteResponse] = []
    @Published var roundResults: RoundResultResponse?
    @Published var timeRemaining: TimeInterval?
    @Published var selectedCard: CardResponse?
    @Published var isAnonymous: Bool = false
    
    private var gameTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init(gameRepository: GameRepositoryProtocol = GameRepository(),
         cardsRepository: CardsRepositoryProtocol = CardsRepository()) {
        self.gameRepository = gameRepository
        self.cardsRepository = cardsRepository
        super.init()
        
        setupWebSocketObservers()
    }
    
    // MARK: - Game Initialization
    
    func initializeGame(roomId: Int) async {
        setLoading(true)
        
        do {
            // Connect to WebSocket
            try await webSocketManager.connect(roomId: roomId)
            
            // Get current game state
            if let game = try await gameRepository.getCurrentGame(roomId: roomId) {
                currentGame = game
                currentRound = game.current_round
                
                // Get my cards for the game
                myCards = try await gameRepository.getMyCardsForGame()
                
                // Get current round choices if voting is active
                if let round = currentRound, round.status == .voting {
                    roundChoices = try await gameRepository.getRoundChoices(roundId: round.id)
                }
                
                // Start game timer
                startGameTimer()
            }
            
            setLoading(false)
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - Card Selection
    
    func selectCard(_ card: CardResponse) {
        selectedCard = card
    }
    
    func toggleAnonymous() {
        isAnonymous.toggle()
    }
    
    func submitCardChoice() async {
        guard let card = selectedCard,
              let round = currentRound,
              round.status == .choosing else { return }
        
        setLoading(true)
        
        do {
            _ = try await gameRepository.submitChoice(
                roundId: round.id,
                cardId: card.id,
                isAnonymous: isAnonymous
            )
            
            // Clear selection
            selectedCard = nil
            
            setLoading(false)
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - Voting
    
    func submitVote(for userId: Int) async {
        guard let round = currentRound,
              round.status == .voting else { return }
        
        setLoading(true)
        
        do {
            _ = try await gameRepository.submitVote(
                roundId: round.id,
                votedForUserId: userId
            )
            
            setLoading(false)
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - Game Management
    
    func startVoting() async {
        guard let round = currentRound else { return }
        
        setLoading(true)
        
        do {
            let response = try await gameRepository.startVoting(roundId: round.id)
            roundChoices = response.choices
            
            setLoading(false)
        } catch {
            handleError(error)
        }
    }
    
    func endGame() async {
        guard currentGame != nil else { return }
        
        setLoading(true)
        
        do {
            let response = try await gameRepository.endGame(gameId: currentGame!.game.id)
            
            // Update game state - create new instance since properties are let
            if let winner = response.winner {
                currentGame = GameDetailResponse(
                    game: GameResponse(
                        id: currentGame!.game.id,
                        room_id: currentGame!.game.room_id,
                        status: .finished,
                        current_round: currentGame!.game.current_round,
                        total_rounds: currentGame!.game.total_rounds,
                        created_at: currentGame!.game.created_at,
                        started_at: currentGame!.game.started_at,
                        finished_at: Date(),
                        winner_id: winner.id,
                        winner_nickname: winner.nickname
                    ),
                    players: currentGame!.players,
                    current_round: currentGame!.current_round,
                    rounds: currentGame!.rounds,
                    winner: winner
                )
            }
            
            setLoading(false)
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - WebSocket Event Handling
    
    private func setupWebSocketObservers() {
        // Game started
        NotificationCenter.default.publisher(for: .gameStarted)
            .sink { [weak self] notification in
                self?.handleGameStarted(notification.object as? [String: Any])
            }
            .store(in: &cancellables)
        
        // Round started
        NotificationCenter.default.publisher(for: .roundStarted)
            .sink { [weak self] notification in
                self?.handleRoundStarted(notification.object as? [String: Any])
            }
            .store(in: &cancellables)
        
        // Voting started
        NotificationCenter.default.publisher(for: .votingStarted)
            .sink { [weak self] notification in
                self?.handleVotingStarted(notification.object as? [String: Any])
            }
            .store(in: &cancellables)
        
        // Round ended
        NotificationCenter.default.publisher(for: .roundEnded)
            .sink { [weak self] notification in
                self?.handleRoundEnded(notification.object as? [String: Any])
            }
            .store(in: &cancellables)
        
        // Game ended
        NotificationCenter.default.publisher(for: .gameEnded)
            .sink { [weak self] notification in
                self?.handleGameEnded(notification.object as? [String: Any])
            }
            .store(in: &cancellables)
        
        // Game state update
        NotificationCenter.default.publisher(for: .gameStateUpdate)
            .sink { [weak self] notification in
                self?.handleGameStateUpdate(notification.object as? [String: Any])
            }
            .store(in: &cancellables)
    }
    
    private func handleGameStarted(_ data: [String: Any]?) {
        // Handle game started event
        Task {
            await refreshGameState()
        }
    }
    
    private func handleRoundStarted(_ data: [String: Any]?) {
        // Handle round started event
        Task {
            await refreshGameState()
        }
    }
    
    private func handleVotingStarted(_ data: [String: Any]?) {
        // Handle voting started event
        Task {
            await refreshGameState()
        }
    }
    
    private func handleRoundEnded(_ data: [String: Any]?) {
        // Handle round ended event
        Task {
            await refreshGameState()
        }
    }
    
    private func handleGameEnded(_ data: [String: Any]?) {
        // Handle game ended event
        Task {
            await refreshGameState()
        }
    }
    
    private func handleGameStateUpdate(_ data: [String: Any]?) {
        // Handle game state update event
        Task {
            await refreshGameState()
        }
    }
    
    // MARK: - Game State Refresh
    
    private func refreshGameState() async {
        guard let game = currentGame else { return }
        
        do {
            let state = try await gameRepository.getActionStatus(roundId: currentRound?.id ?? 0)
            gameState = state
            currentRound = state.current_round
            timeRemaining = state.time_remaining
        } catch {
            print("Failed to refresh game state: \(error)")
        }
    }
    
    // MARK: - Timer Management
    
    private func startGameTimer() {
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTimer()
            }
        }
    }
    
    private func stopGameTimer() {
        gameTimer?.invalidate()
        gameTimer = nil
    }
    
    private func updateTimer() {
        guard let remaining = timeRemaining else { return }
        
        if remaining > 0 {
            timeRemaining = remaining - 1
        } else {
            // Time's up
            stopGameTimer()
        }
    }
    
    // MARK: - Computed Properties
    
    var isGameActive: Bool {
        return currentGame?.game.isActive ?? false
    }
    
    var isGameFinished: Bool {
        return currentGame?.game.isFinished ?? false
    }
    
    var canSubmitChoice: Bool {
        return gameState?.can_submit_choice ?? false
    }
    
    var canVote: Bool {
        return gameState?.can_vote ?? false
    }
    
    var canStartVoting: Bool {
        return gameState?.can_start_voting ?? false
    }
    
    var canEndGame: Bool {
        return gameState?.can_end_game ?? false
    }
    
    var formattedTimeRemaining: String {
        guard let remaining = timeRemaining else { return "N/A" }
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var currentSituation: String {
        return currentRound?.situation ?? "Ожидание ситуации..."
    }
    
    var roundNumber: String {
        guard let game = currentGame else { return "0/0" }
        return "\(game.game.current_round ?? 0)/\(game.game.total_rounds)"
    }
    
    // MARK: - Cleanup
    
    override func cleanup() {
        stopGameTimer()
        webSocketManager.disconnect()
        cancellables.removeAll()
        super.cleanup()
    }
    
    deinit {
        Task { @MainActor in
            cleanup()
        }
    }
} 