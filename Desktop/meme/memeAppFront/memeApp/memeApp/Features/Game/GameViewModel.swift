import Foundation
import Combine
import os

@MainActor
class GameViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var gameState: GameState = .waiting
    @Published var currentGame: Game?
    @Published var currentRound: Round?
    @Published var myCards: [UserCardResponse] = []
    @Published var roundChoices: [RoundChoice] = []
    @Published var timeRemaining: Int = 0
    @Published var errorMessage: String = ""
    @Published var isLoading = false
    
    // MARK: - Private Properties
    private let roomService: RoomServiceProtocol
    private let gameService: GameServiceProtocol
    private let webSocketManager: WebSocketManagerProtocol
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: "com.memegame.app", category: "game")
    
    private var currentRoomId: Int?
    private var timer: Timer?
    
    // MARK: - Game States
    enum GameState {
        case waiting
        case choosing
        case voting
        case roundEnd
        case gameEnd
        case error
    }
    
    // MARK: - Initialization
    init(
        roomService: RoomServiceProtocol = RoomService(),
        gameService: GameServiceProtocol = GameService(),
        webSocketManager: WebSocketManagerProtocol = WebSocketManager.shared
    ) {
        self.roomService = roomService
        self.gameService = gameService
        self.webSocketManager = webSocketManager
        
        setupWebSocketSubscriptions()
    }
    
    // MARK: - Public Methods
    
    func joinGame(roomId: Int) async {
        logger.debug("Joining game in room: \(roomId)")
        isLoading = true
        errorMessage = ""
        
        do {
            // 1. Присоединяемся к комнате
            let room = try await roomService.joinRoom(roomId: roomId)
            currentRoomId = room.id
            
            // 2. Подключаемся к WebSocket
            try await webSocketManager.connect(roomId: roomId)
            try await webSocketManager.joinRoom(roomId: roomId)
            
            // 3. Получаем карты для игры
            myCards = try await gameService.getMyCardsForGame()
            
            // 4. Получаем текущую игру
            if let game = try await gameService.getCurrentGame(roomId: roomId) {
                currentGame = game
                gameState = game.status == .playing ? .choosing : .waiting
            }
            
            logger.debug("Successfully joined game")
            
        } catch {
            logger.error("Failed to join game: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            gameState = .error
        }
        
        isLoading = false
    }
    
    func leaveGame() async {
        logger.debug("Leaving game")
        
        stopTimer()
        webSocketManager.disconnect()
        
        if let roomId = currentRoomId {
            try? await roomService.leaveRoom(roomId: roomId)
        }
        
        resetGame()
    }
    
    func startGame() async {
        guard let roomId = currentRoomId else { return }
        
        logger.debug("Starting game")
        isLoading = true
        
        do {
            try await roomService.startGame(roomId: roomId)
            logger.debug("Game start request sent")
        } catch {
            logger.error("Failed to start game: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func playCard(_ card: UserCardResponse) async {
        guard let round = currentRound else { return }
        
        logger.debug("Playing card: \(card.name)")
        isLoading = true
        
        do {
            // Отправляем через WebSocket
            try await webSocketManager.playCard(roundId: round.id, cardId: card.cardId)
            
            // Также отправляем через REST API для надежности
            try await gameService.submitChoice(roundId: round.id, cardId: card.cardId)
            
            logger.debug("Card played successfully")
            
        } catch {
            logger.error("Failed to play card: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func submitVote(for choice: RoundChoice) async {
        guard let round = currentRound else { return }
        
        logger.debug("Submitting vote for choice: \(choice.id)")
        isLoading = true
        
        do {
            // Отправляем через WebSocket
            try await webSocketManager.submitVote(roundId: round.id, choiceId: choice.id)
            
            // Также отправляем через REST API для надежности
            try await gameService.submitVote(roundId: round.id, choiceId: choice.id)
            
            logger.debug("Vote submitted successfully")
            
        } catch {
            logger.error("Failed to submit vote: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    private func setupWebSocketSubscriptions() {
        webSocketManager.messagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleWebSocketEvent(event)
            }
            .store(in: &cancellables)
    }
    
    private func handleWebSocketEvent(_ event: WebSocketEvent) {
        switch event {
        case .gameStarted(let data):
            currentGame = data.game
            gameState = .choosing
            loadGameCards()
            
        case .roundStarted(let data):
            currentRound = data.round
            gameState = .choosing
            startTimer(data.time_limit)
            
        case .cardPlayed(let data):
            // Обновляем выборы в раунде
            if let round = currentRound, round.id == data.choice.round_id {
                var updatedRound = round
                updatedRound.choices.append(data.choice)
                currentRound = updatedRound
            }
            
        case .votingStarted(let data):
            roundChoices = data.choices
            gameState = .voting
            startTimer(data.time_limit)
            
        case .voteSubmitted(let data):
            // Обновляем голоса в раунде
            if let round = currentRound {
                var updatedRound = round
                let vote = RoundVote(
                    id: data.vote.id,
                    round_id: data.vote.round_id,
                    voter_id: data.vote.voter_id,
                    choice_id: data.vote.choice_id,
                    created_at: data.vote.created_at
                )
                updatedRound.votes.append(vote)
                currentRound = updatedRound
            }
            
        case .roundEnded(let data):
            currentRound = data.round
            gameState = .roundEnd
            stopTimer()
            
        case .gameEnded(let data):
            currentGame = data.game
            gameState = .gameEnd
            stopTimer()
            
        case .timerUpdate(let data):
            timeRemaining = data.time_remaining
            
        case .error(let data):
            errorMessage = data.message
            gameState = .error
            
        case .connectionLost:
            errorMessage = "Соединение потеряно"
            gameState = .error
            
        default:
            break
        }
    }
    
    private func loadGameCards() {
        Task {
            do {
                myCards = try await gameService.getMyCardsForGame()
            } catch {
                logger.error("Failed to load game cards: \(error.localizedDescription)")
            }
        }
    }
    
    private func startTimer(_ seconds: Int) {
        stopTimer()
        timeRemaining = seconds
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.stopTimer()
                // Время истекло, можно показать сообщение
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        timeRemaining = 0
    }
    
    private func resetGame() {
        currentGame = nil
        currentRound = nil
        myCards = []
        roundChoices = []
        timeRemaining = 0
        errorMessage = ""
        gameState = .waiting
        currentRoomId = nil
    }
} 