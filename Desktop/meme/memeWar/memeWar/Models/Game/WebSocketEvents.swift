//
//  WebSocketEvents.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import Foundation

// MARK: - WebSocket Message

struct WebSocketMessage: Codable {
    let action: String
    let data: [String: Any]
    
    enum CodingKeys: String, CodingKey {
        case action
        case data
    }
    
    init(action: String, data: [String: Any] = [:]) {
        self.action = action
        self.data = data
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        action = try container.decode(String.self, forKey: .action)
        
        // Decode data as JSON and convert to [String: Any]
        let jsonData = try container.decode(Data.self, forKey: .data)
        if let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            data = jsonObject
        } else {
            data = [:]
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(action, forKey: .action)
        
        // Convert [String: Any] to JSON Data
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        try container.encode(jsonData, forKey: .data)
    }
}

// MARK: - WebSocket Actions

enum WebSocketAction: String, CaseIterable {
    case ping = "ping"
    case joinRoom = "join_room"
    case leaveRoom = "leave_room"
    case startGame = "start_game"
    case submitCardChoice = "submit_card_choice"
    case submitVote = "submit_vote"
    case startVoting = "start_voting"
    case getGameState = "get_game_state"
}

// MARK: - WebSocket Event Types

enum WebSocketEventType: String, Codable {
    case pong = "pong"
    case roomStateChanged = "room_state_changed"
    case gameStarted = "game_started"
    case roundStarted = "round_started"
    case votingStarted = "voting_started"
    case roundEnded = "round_ended"
    case gameEnded = "game_ended"
    case playerJoined = "player_joined"
    case playerLeft = "player_left"
    case timeoutWarning = "timeout_warning"
    case playerTimeout = "player_timeout"
}

// MARK: - WebSocket Event

struct WebSocketEvent: Codable {
    let type: WebSocketEventType
    let data: [String: Any]
    let timestamp: String
    
    enum CodingKeys: String, CodingKey {
        case type
        case data
        case timestamp
    }
    
    init(type: WebSocketEventType, data: [String: Any] = [:]) {
        self.type = type
        self.data = data
        self.timestamp = ISO8601DateFormatter().string(from: Date())
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(WebSocketEventType.self, forKey: .type)
        
        // Decode data as JSON and convert to [String: Any]
        let jsonData = try container.decode(Data.self, forKey: .data)
        if let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            data = jsonObject
        } else {
            data = [:]
        }
        
        timestamp = try container.decode(String.self, forKey: .timestamp)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        
        // Convert [String: Any] to JSON Data
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        try container.encode(jsonData, forKey: .data)
        
        try container.encode(timestamp, forKey: .timestamp)
    }
}

// MARK: - WebSocket Message Extensions

extension WebSocketMessage {
    static func ping() -> WebSocketMessage {
        return WebSocketMessage(action: WebSocketAction.ping.rawValue)
    }
    
    static func joinRoom(roomId: Int) -> WebSocketMessage {
        return WebSocketMessage(
            action: WebSocketAction.joinRoom.rawValue,
            data: ["room_id": roomId]
        )
    }
    
    static func leaveRoom(roomId: Int) -> WebSocketMessage {
        return WebSocketMessage(
            action: WebSocketAction.leaveRoom.rawValue,
            data: ["room_id": roomId]
        )
    }
    
    static func startGame(roomId: Int) -> WebSocketMessage {
        return WebSocketMessage(
            action: WebSocketAction.startGame.rawValue,
            data: ["room_id": roomId]
        )
    }
    
    static func submitCardChoice(roundId: Int, cardId: String, isAnonymous: Bool) -> WebSocketMessage {
        return WebSocketMessage(
            action: WebSocketAction.submitCardChoice.rawValue,
            data: [
                "round_id": roundId,
                "card_id": cardId,
                "is_anonymous": isAnonymous
            ]
        )
    }
    
    static func submitVote(roundId: Int, votedForUserId: Int) -> WebSocketMessage {
        return WebSocketMessage(
            action: WebSocketAction.submitVote.rawValue,
            data: [
                "round_id": roundId,
                "voted_for_user_id": votedForUserId
            ]
        )
    }
    
    static func startVoting(roundId: Int) -> WebSocketMessage {
        return WebSocketMessage(
            action: WebSocketAction.startVoting.rawValue,
            data: ["round_id": roundId]
        )
    }
    
    static func getGameState(roomId: Int) -> WebSocketMessage {
        return WebSocketMessage(
            action: WebSocketAction.getGameState.rawValue,
            data: ["room_id": roomId]
        )
    }
} 