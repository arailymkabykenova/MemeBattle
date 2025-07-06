//
//  WebSocketManager.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import Foundation
import Combine

class WebSocketManager: ObservableObject {
    static let shared = WebSocketManager()
    
    private var webSocket: URLSessionWebSocketTask?
    private let baseURL: String
    private let tokenManager = TokenManager.shared
    
    @Published var isConnected = false
    @Published var lastError: String?
    @Published var connectionStatus: ConnectionStatus = .disconnected
    
    private var pingTimer: Timer?
    private var reconnectTimer: Timer?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private let reconnectDelay: TimeInterval = 2.0
    
    enum ConnectionStatus {
        case disconnected
        case connecting
        case connected
        case reconnecting
        case error
    }
    
    private init() {
        self.baseURL = APIConstants.wsBaseURL
    }
    
    // MARK: - Connection Management
    
    func connect(roomId: Int? = nil) async throws {
        guard let token = tokenManager.getToken() else {
            throw NetworkError.unauthorized
        }
        
        connectionStatus = .connecting
        
        var urlComponents = URLComponents(string: "\(baseURL)/websocket/ws")!
        urlComponents.queryItems = [
            URLQueryItem(name: "token", value: token)
        ]
        
        if let roomId = roomId {
            urlComponents.queryItems?.append(URLQueryItem(name: "room_id", value: "\(roomId)"))
        }
        
        guard let url = urlComponents.url else {
            throw NetworkError.invalidURL
        }
        
        let request = URLRequest(url: url)
        let session = URLSession(configuration: .default)
        webSocket = session.webSocketTask(with: request)
        
        webSocket?.resume()
        
        // Start listening for messages
        await receiveMessages()
        
        // Start ping timer
        startPingTimer()
        
        connectionStatus = .connected
        isConnected = true
        reconnectAttempts = 0
    }
    
    func disconnect() {
        stopPingTimer()
        stopReconnectTimer()
        
        webSocket?.cancel()
        webSocket = nil
        
        connectionStatus = .disconnected
        isConnected = false
        reconnectAttempts = 0
    }
    
    // MARK: - Message Handling
    
    func sendMessage(_ message: WebSocketMessage) async throws {
        guard let webSocket = webSocket else {
            throw NetworkError.notConnected
        }
        
        do {
            let data = try JSONEncoder().encode(message)
            let webSocketMessage = URLSessionWebSocketTask.Message.data(data)
            
            try await webSocket.send(webSocketMessage)
        } catch {
            throw NetworkError.networkError(error)
        }
    }
    
    private func receiveMessages() async {
        guard let webSocket = webSocket else { return }
        
        do {
            let message = try await webSocket.receive()
            
            switch message {
            case .data(let data):
                let event = try JSONDecoder().decode(WebSocketEvent.self, from: data)
                await handleWebSocketEvent(event)
            case .string(let string):
                if let data = string.data(using: .utf8) {
                    let event = try JSONDecoder().decode(WebSocketEvent.self, from: data)
                    await handleWebSocketEvent(event)
                }
            @unknown default:
                break
            }
            
            // Continue listening
            await receiveMessages()
            
        } catch {
            await handleConnectionError(error)
        }
    }
    
    @MainActor
    private func handleWebSocketEvent(_ event: WebSocketEvent) {
        // Handle events and notify ViewModels
        switch event.type {
        case .pong:
            // Handle ping/pong for connection maintenance
            break
        case .roomStateChanged:
            NotificationCenter.default.post(name: .roomStateChanged, object: event.data)
        case .gameStarted:
            NotificationCenter.default.post(name: .gameStarted, object: event.data)
        case .roundStarted:
            NotificationCenter.default.post(name: .roundStarted, object: event.data)
        case .votingStarted:
            NotificationCenter.default.post(name: .votingStarted, object: event.data)
        case .roundEnded:
            NotificationCenter.default.post(name: .roundEnded, object: event.data)
        case .gameEnded:
            NotificationCenter.default.post(name: .gameEnded, object: event.data)
        case .playerJoined:
            NotificationCenter.default.post(name: .playerJoined, object: event.data)
        case .playerLeft:
            NotificationCenter.default.post(name: .playerLeft, object: event.data)
        case .timeoutWarning:
            NotificationCenter.default.post(name: .timeoutWarning, object: event.data)
        case .playerTimeout:
            NotificationCenter.default.post(name: .playerTimeout, object: event.data)
        case .cardChoiceSubmitted:
            NotificationCenter.default.post(name: .cardChoiceSubmitted, object: event.data)
        case .voteSubmitted:
            NotificationCenter.default.post(name: .voteSubmitted, object: event.data)
        case .gameStateUpdate:
            NotificationCenter.default.post(name: .gameStateUpdate, object: event.data)
        case .error:
            NotificationCenter.default.post(name: .websocketError, object: event.data)
        }
    }
    
    @MainActor
    private func handleConnectionError(_ error: Error) {
        lastError = error.localizedDescription
        connectionStatus = .error
        isConnected = false
        
        // Attempt to reconnect
        if reconnectAttempts < maxReconnectAttempts {
            attemptReconnect()
        }
    }
    
    // MARK: - Ping/Pong
    
    private func startPingTimer() {
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task {
                await self?.sendPing()
            }
        }
    }
    
    private func stopPingTimer() {
        pingTimer?.invalidate()
        pingTimer = nil
    }
    
    private func sendPing() async {
        do {
            let pingMessage = WebSocketMessage.ping()
            try await sendMessage(pingMessage)
        } catch {
            print("Failed to send ping: \(error)")
        }
    }
    
    // MARK: - Reconnection
    
    private func attemptReconnect() {
        connectionStatus = .reconnecting
        reconnectAttempts += 1
        
        stopReconnectTimer()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: reconnectDelay, repeats: false) { [weak self] _ in
            Task {
                await self?.performReconnect()
            }
        }
    }
    
    private func stopReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    private func performReconnect() async {
        do {
            try await connect()
        } catch {
            await handleConnectionError(error)
        }
    }
    
    // MARK: - Convenience Methods
    
    func joinRoom(_ roomId: Int) async throws {
        let message = WebSocketMessage.joinRoom(roomId: roomId)
        try await sendMessage(message)
    }
    
    func leaveRoom(_ roomId: Int) async throws {
        let message = WebSocketMessage.leaveRoom(roomId: roomId)
        try await sendMessage(message)
    }
    
    func startGame(_ roomId: Int) async throws {
        let message = WebSocketMessage.startGame(roomId: roomId)
        try await sendMessage(message)
    }
    
    func submitCardChoice(roundId: Int, cardId: String, isAnonymous: Bool) async throws {
        let message = WebSocketMessage.submitCardChoice(roundId: roundId, cardId: cardId, isAnonymous: isAnonymous)
        try await sendMessage(message)
    }
    
    func submitVote(roundId: Int, votedForUserId: Int) async throws {
        let message = WebSocketMessage.submitVote(roundId: roundId, votedForUserId: votedForUserId)
        try await sendMessage(message)
    }
    
    func startVoting(roundId: Int) async throws {
        let message = WebSocketMessage.startVoting(roundId: roundId)
        try await sendMessage(message)
    }
    
    func getGameState(roomId: Int) async throws {
        let message = WebSocketMessage.getGameState(roomId: roomId)
        try await sendMessage(message)
    }
}

// MARK: - WebSocket Error Handling

extension WebSocketManager {
    enum WebSocketError: LocalizedError {
        case connectionFailed
        case messageEncodingFailed
        case messageDecodingFailed
        case unexpectedMessageType
        
        var errorDescription: String? {
            switch self {
            case .connectionFailed:
                return "Не удалось подключиться к серверу"
            case .messageEncodingFailed:
                return "Ошибка кодирования сообщения"
            case .messageDecodingFailed:
                return "Ошибка декодирования сообщения"
            case .unexpectedMessageType:
                return "Неожиданный тип сообщения"
            }
        }
    }
} 