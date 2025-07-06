//
//  WebSocketManager.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import Foundation
import Combine
import UIKit

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
        
        let data = try JSONEncoder().encode(message)
        let webSocketMessage = URLSessionWebSocketTask.Message.data(data)
        
        try await webSocket.send(webSocketMessage)
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
        case .roomStateChanged:
            NotificationCenter.default.post(
                name: Notification.Name.roomStateChanged,
                object: nil,
                userInfo: ["data": event.data]
            )
        case .gameStarted:
            NotificationCenter.default.post(
                name: Notification.Name.gameStarted,
                object: nil,
                userInfo: ["data": event.data]
            )
        case .roundStarted:
            NotificationCenter.default.post(
                name: Notification.Name.roundStarted,
                object: nil,
                userInfo: ["data": event.data]
            )
        case .votingStarted:
            NotificationCenter.default.post(
                name: Notification.Name.votingStarted,
                object: nil,
                userInfo: ["data": event.data]
            )
        case .roundEnded:
            NotificationCenter.default.post(
                name: Notification.Name.roundEnded,
                object: nil,
                userInfo: ["data": event.data]
            )
        case .gameEnded:
            NotificationCenter.default.post(
                name: Notification.Name.gameEnded,
                object: nil,
                userInfo: ["data": event.data]
            )
        case .playerJoined:
            NotificationCenter.default.post(
                name: Notification.Name.playerJoined,
                object: nil,
                userInfo: ["data": event.data]
            )
        case .playerLeft:
            NotificationCenter.default.post(
                name: Notification.Name.playerLeft,
                object: nil,
                userInfo: ["data": event.data]
            )
        case .timeoutWarning:
            NotificationCenter.default.post(
                name: Notification.Name.timeoutWarning,
                object: nil,
                userInfo: ["data": event.data]
            )
        case .playerTimeout:
            NotificationCenter.default.post(
                name: Notification.Name.playerTimeout,
                object: nil,
                userInfo: ["data": event.data]
            )
        case .pong:
            // Handle ping/pong for connection maintenance
            break
        }
    }
    
    // MARK: - WebSocket Event Decoding
    
    private func decodeWebSocketEvent(from data: Data) throws -> WebSocketEvent {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            
            // Try ISO8601 with fractional seconds (server format: 2025-07-06T04:00:10.402520)
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: dateStr) {
                return date
            }
            
            // Try standard ISO8601 without fractional seconds
            let standardISOFormatter = ISO8601DateFormatter()
            standardISOFormatter.formatOptions = [.withInternetDateTime]
            if let date = standardISOFormatter.date(from: dateStr) {
                return date
            }
            
            // Try DateFormatter with specific format for fractional seconds
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            if let date = dateFormatter.date(from: dateStr) {
                return date
            }
            
            // Try date-only format (yyyy-MM-dd)
            let dateOnlyFormatter = DateFormatter()
            dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
            dateOnlyFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateOnlyFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            if let date = dateOnlyFormatter.date(from: dateStr) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string: \(dateStr)")
        }
        
        return try decoder.decode(WebSocketEvent.self, from: data)
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