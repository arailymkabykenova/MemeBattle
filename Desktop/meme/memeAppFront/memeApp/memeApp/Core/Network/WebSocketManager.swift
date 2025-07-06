import Foundation
import os
import Combine

protocol WebSocketManagerProtocol {
    func connect(roomId: Int) async throws
    func disconnect()
    func send(_ message: WebSocketMessage) async throws
    func joinRoom(roomId: Int) async throws
    func leaveRoom(roomId: Int) async throws
    func playCard(roundId: Int, cardId: Int) async throws
    func submitVote(roundId: Int, choiceId: Int) async throws
    func ping() async throws
    var isConnected: Bool { get }
    var connectionState: WebSocketManager.ConnectionState { get }
    var messagePublisher: AnyPublisher<WebSocketEvent, Never> { get }
}

@MainActor
class WebSocketManager: ObservableObject, WebSocketManagerProtocol {
    static let shared = WebSocketManager()
    
    @Published var isConnected = false
    @Published var connectionState: ConnectionState = .disconnected
    @Published var lastError: String?
    
    private var webSocket: URLSessionWebSocketTask?
    private var session: URLSession
    private var reconnectTimer: Timer?
    private var pingTimer: Timer?
    var messagePublisher: AnyPublisher<WebSocketEvent, Never> {
        messageSubject.eraseToAnyPublisher()
    }
    private var messageSubject = PassthroughSubject<WebSocketEvent, Never>()
    private let logger = Logger(subsystem: "com.memegame.app", category: "websocket")
    
    enum ConnectionState {
        case disconnected
        case connecting
        case connected
        case reconnecting
        case error
    }
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Public Methods
    
    func connect(roomId: Int) async throws {
        logger.debug("Connecting to WebSocket for room: \(roomId)")
        connectionState = .connecting
        
        guard let token = KeychainManager.shared.getToken() else {
            throw WebSocketError.noToken
        }
        
        let urlString = "\(APIConfig.wsURL)?token=\(token)&room_id=\(roomId)"
        guard let url = URL(string: urlString) else {
            throw WebSocketError.invalidURL
        }
        
        let request = URLRequest(url: url)
        webSocket = session.webSocketTask(with: request)
        webSocket?.resume()
        
        // Начинаем слушать сообщения
        await receiveMessages()
        
        // Запускаем ping/pong
        startPingTimer()
        
        isConnected = true
        connectionState = .connected
        logger.debug("WebSocket connected successfully")
    }
    
    func disconnect() {
        logger.debug("Disconnecting WebSocket")
        
        stopPingTimer()
        stopReconnectTimer()
        
        webSocket?.cancel(with: .normalClosure, reason: nil)
        webSocket = nil
        
        isConnected = false
        connectionState = .disconnected
        logger.debug("WebSocket disconnected")
    }
    
    func send(_ message: WebSocketMessage) async throws {
        guard isConnected, let webSocket = webSocket else {
            throw WebSocketError.notConnected
        }
        
        do {
            let data = try JSONEncoder().encode(message)
            let wsMessage = URLSessionWebSocketTask.Message.data(data)
            
            try await webSocket.send(wsMessage)
            logger.debug("Sent WebSocket message: \(message.action)")
        } catch {
            logger.error("Failed to send WebSocket message: \(error.localizedDescription)")
            throw WebSocketError.sendFailed(error)
        }
    }
    
    // MARK: - Message Sending Helpers
    
    func joinRoom(roomId: Int) async throws {
        let message = WebSocketMessage(
            action: "join_room",
            data: ["room_id": AnyCodable(roomId)],
            timestamp: ISO8601DateFormatter().string(from: Date()),
            room_id: roomId
        )
        try await send(message)
    }
    
    func leaveRoom(roomId: Int) async throws {
        let message = WebSocketMessage(
            action: "leave_room",
            data: ["room_id": AnyCodable(roomId)],
            timestamp: ISO8601DateFormatter().string(from: Date()),
            room_id: roomId
        )
        try await send(message)
    }
    
    func playCard(roundId: Int, cardId: Int) async throws {
        let message = WebSocketMessage(
            action: "play_card",
            data: [
                "round_id": AnyCodable(roundId),
                "card_id": AnyCodable(cardId)
            ],
            timestamp: ISO8601DateFormatter().string(from: Date()),
            room_id: nil
        )
        try await send(message)
    }
    
    func submitVote(roundId: Int, choiceId: Int) async throws {
        let message = WebSocketMessage(
            action: "submit_vote",
            data: [
                "round_id": AnyCodable(roundId),
                "choice_id": AnyCodable(choiceId)
            ],
            timestamp: ISO8601DateFormatter().string(from: Date()),
            room_id: nil
        )
        try await send(message)
    }
    
    func ping() async throws {
        let message = WebSocketMessage(
            action: "ping",
            data: [:],
            timestamp: ISO8601DateFormatter().string(from: Date()),
            room_id: nil
        )
        try await send(message)
    }
    
    // MARK: - Private Methods
    
    private func receiveMessages() async {
        guard let webSocket = webSocket else { return }
        
        do {
            let message = try await webSocket.receive()
            
            switch message {
            case .data(let data):
                await handleMessage(data)
            case .string(let string):
                if let data = string.data(using: .utf8) {
                    await handleMessage(data)
                }
            @unknown default:
                logger.warning("Unknown WebSocket message type")
            }
            
            // Продолжаем слушать
            await receiveMessages()
            
        } catch {
            logger.error("WebSocket receive error: \(error.localizedDescription)")
            await handleDisconnection()
        }
    }
    
    private func handleMessage(_ data: Data) async {
        do {
            let message = try JSONDecoder().decode(WebSocketMessage.self, from: data)
            logger.debug("Received WebSocket message: \(message.action)")
            
            let event = try parseWebSocketEvent(message)
            messageSubject.send(event)
            
        } catch {
            logger.error("Failed to parse WebSocket message: \(error.localizedDescription)")
        }
    }
    
    private func parseWebSocketEvent(_ message: WebSocketMessage) throws -> WebSocketEvent {
        switch message.action {
        case "player_joined":
            let data = try parseData(PlayerJoinedData.self, from: message.data)
            return .playerJoined(data)
            
        case "player_left":
            let data = try parseData(PlayerLeftData.self, from: message.data)
            return .playerLeft(data)
            
        case "game_started":
            let data = try parseData(GameStartedData.self, from: message.data)
            return .gameStarted(data)
            
        case "round_started":
            let data = try parseData(RoundStartedData.self, from: message.data)
            return .roundStarted(data)
            
        case "card_played":
            let data = try parseData(CardPlayedData.self, from: message.data)
            return .cardPlayed(data)
            
        case "voting_started":
            let data = try parseData(VotingStartedData.self, from: message.data)
            return .votingStarted(data)
            
        case "vote_submitted":
            let data = try parseData(VoteSubmittedData.self, from: message.data)
            return .voteSubmitted(data)
            
        case "round_ended":
            let data = try parseData(RoundEndedData.self, from: message.data)
            return .roundEnded(data)
            
        case "game_ended":
            let data = try parseData(GameEndedData.self, from: message.data)
            return .gameEnded(data)
            
        case "error":
            let data = try parseData(ErrorData.self, from: message.data)
            return .error(data)
            
        case "timer_update":
            let data = try parseData(TimerUpdateData.self, from: message.data)
            return .timerUpdate(data)
            
        case "pong":
            // Игнорируем pong сообщения
            throw WebSocketError.unknownEvent(message.action)
            
        default:
            throw WebSocketError.unknownEvent(message.action)
        }
    }
    
    private func parseData<T: Codable>(_ type: T.Type, from data: [String: AnyCodable]) throws -> T {
        let jsonData = try JSONSerialization.data(withJSONObject: data.mapValues { $0.value })
        return try JSONDecoder().decode(type, from: jsonData)
    }
    
    private func handleDisconnection() async {
        logger.warning("WebSocket disconnected")
        
        isConnected = false
        connectionState = .error
        lastError = "Connection lost"
        
        // Пытаемся переподключиться
        startReconnectTimer()
    }
    
    private func startPingTimer() {
        stopPingTimer()
        
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task {
                try? await self?.ping()
            }
        }
    }
    
    private func stopPingTimer() {
        pingTimer?.invalidate()
        pingTimer = nil
    }
    
    private func startReconnectTimer() {
        stopReconnectTimer()
        
        connectionState = .reconnecting
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task {
                // Попытка переподключения
                self?.logger.debug("Attempting to reconnect WebSocket")
            }
        }
    }
    
    private func stopReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
}

// MARK: - WebSocket Errors

enum WebSocketError: Error, LocalizedError {
    case noToken
    case invalidURL
    case notConnected
    case sendFailed(Error)
    case unknownEvent(String)
    case connectionFailed
    
    var errorDescription: String? {
        switch self {
        case .noToken:
            return "No authentication token available"
        case .invalidURL:
            return "Invalid WebSocket URL"
        case .notConnected:
            return "WebSocket is not connected"
        case .sendFailed(let error):
            return "Failed to send message: \(error.localizedDescription)"
        case .unknownEvent(let event):
            return "Unknown WebSocket event: \(event)"
        case .connectionFailed:
            return "Failed to connect to WebSocket"
        }
    }
} 