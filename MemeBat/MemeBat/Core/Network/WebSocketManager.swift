import Foundation
import os

// MARK: - WebSocket Manager Protocol
protocol WebSocketManagerProtocol {
    func connect(roomId: Int, token: String) async throws
    func disconnect()
    func sendMessage(_ message: WebSocketMessage) async throws
    var isConnected: Bool { get }
    var onMessageReceived: ((WebSocketMessage) -> Void)? { get set }
    var onConnectionStatusChanged: ((Bool) -> Void)? { get set }
}

// MARK: - WebSocket Manager
class WebSocketManager: NSObject, WebSocketManagerProtocol {
    static let shared = WebSocketManager()
    
    private var webSocket: URLSessionWebSocketTask?
    private let session: URLSession
    private let logger = Logger(subsystem: "com.memegame.app", category: "websocket")
    
    private var pingTimer: Timer?
    private var reconnectTimer: Timer?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    
    var onMessageReceived: ((WebSocketMessage) -> Void)?
    var onConnectionStatusChanged: ((Bool) -> Void)?
    
    var isConnected: Bool {
        return webSocket?.state == .running
    }
    
    private override init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        
        self.session = URLSession(configuration: config)
        super.init()
    }
    
    // MARK: - Public Methods
    func connect(roomId: Int, token: String) async throws {
        guard let url = URL(string: "\(APIConfig.wsURL)?token=\(token)&room_id=\(roomId)") else {
            logger.error("Invalid WebSocket URL")
            throw NetworkError.invalidURL
        }
        
        let request = URLRequest(url: url)
        webSocket = session.webSocketTask(with: request)
        
        logger.debug("Connecting to WebSocket: \(url)")
        
        webSocket?.resume()
        onConnectionStatusChanged?(true)
        
        // Start listening for messages
        receiveMessage()
        
        // Start ping timer
        startPingTimer()
    }
    
    func disconnect() {
        logger.debug("Disconnecting WebSocket")
        
        pingTimer?.invalidate()
        pingTimer = nil
        
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        
        webSocket?.cancel()
        webSocket = nil
        
        onConnectionStatusChanged?(false)
    }
    
    func sendMessage(_ message: WebSocketMessage) async throws {
        guard isConnected else {
            logger.error("WebSocket not connected")
            throw NetworkError.unknown
        }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(message)
            let wsMessage = URLSessionWebSocketTask.Message.data(data)
            
            webSocket?.send(wsMessage) { error in
                if let error = error {
                    self.logger.error("Failed to send message: \(error.localizedDescription)")
                }
            }
            
            logger.debug("Sent message: \(message.action)")
        } catch {
            logger.error("Failed to encode message: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Private Methods
    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                self.handleMessage(message)
                // Continue receiving messages
                self.receiveMessage()
                
            case .failure(let error):
                self.logger.error("WebSocket receive error: \(error.localizedDescription)")
                self.handleConnectionError()
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .data(let data):
            do {
                let decoder = JSONDecoder()
                let wsMessage = try decoder.decode(WebSocketMessage.self, from: data)
                
                logger.debug("Received message: \(wsMessage.action)")
                onMessageReceived?(wsMessage)
                
                // Handle specific message types
                handleSpecificMessage(wsMessage)
                
            } catch {
                logger.error("Failed to decode WebSocket message: \(error.localizedDescription)")
            }
            
        case .string(let string):
            logger.debug("Received string message: \(string)")
            
        @unknown default:
            logger.error("Unknown WebSocket message type")
        }
    }
    
    private func handleSpecificMessage(_ message: WebSocketMessage) {
        switch message.action {
        case WebSocketAction.pong.rawValue:
            logger.debug("Received pong")
            
        case WebSocketAction.error.rawValue:
            if let errorData = message.data["message"]?.value as? String {
                logger.error("WebSocket error: \(errorData)")
            }
            
        case WebSocketAction.connectionLost.rawValue:
            logger.error("Connection lost")
            handleConnectionError()
            
        default:
            break
        }
    }
    
    private func handleConnectionError() {
        onConnectionStatusChanged?(false)
        
        if reconnectAttempts < maxReconnectAttempts {
            reconnectAttempts += 1
            let delay = Double(reconnectAttempts) * 2.0 // Exponential backoff
            
            logger.debug("Attempting to reconnect in \(delay) seconds (attempt \(reconnectAttempts))")
            
            reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                self?.attemptReconnect()
            }
        } else {
            logger.error("Max reconnection attempts reached")
        }
    }
    
    private func attemptReconnect() {
        guard let token = KeychainManager.shared.getAuthToken() else {
            logger.error("No auth token available for reconnection")
            return
        }
        
        // Note: We need room ID for reconnection, this should be stored in the game state
        logger.debug("Attempting to reconnect...")
        // This would need to be implemented with stored room ID
    }
    
    private func startPingTimer() {
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }
    
    private func sendPing() {
        let pingMessage = WebSocketMessage(
            action: WebSocketAction.ping.rawValue,
            data: [:],
            timestamp: ISO8601DateFormatter().string(from: Date()),
            room_id: nil
        )
        
        Task {
            try? await sendMessage(pingMessage)
        }
    }
}

// MARK: - WebSocket Message Extensions
extension WebSocketMessage {
    static func joinRoom(roomId: Int) -> WebSocketMessage {
        return WebSocketMessage(
            action: WebSocketAction.joinRoom.rawValue,
            data: ["room_id": AnyCodable(roomId)],
            timestamp: ISO8601DateFormatter().string(from: Date()),
            room_id: roomId
        )
    }
    
    static func leaveRoom(roomId: Int) -> WebSocketMessage {
        return WebSocketMessage(
            action: WebSocketAction.leaveRoom.rawValue,
            data: ["room_id": AnyCodable(roomId)],
            timestamp: ISO8601DateFormatter().string(from: Date()),
            room_id: roomId
        )
    }
    
    static func playCard(roomId: Int, cardId: Int) -> WebSocketMessage {
        return WebSocketMessage(
            action: WebSocketAction.playCard.rawValue,
            data: [
                "room_id": AnyCodable(roomId),
                "card_id": AnyCodable(cardId)
            ],
            timestamp: ISO8601DateFormatter().string(from: Date()),
            room_id: roomId
        )
    }
    
    static func submitVote(roomId: Int, playerId: Int) -> WebSocketMessage {
        return WebSocketMessage(
            action: WebSocketAction.submitVote.rawValue,
            data: [
                "room_id": AnyCodable(roomId),
                "player_id": AnyCodable(playerId)
            ],
            timestamp: ISO8601DateFormatter().string(from: Date()),
            room_id: roomId
        )
    }
} 