//
//  WebSocketEvents.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import Foundation

// MARK: - WebSocket Message Structure

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

// MARK: - WebSocket Actions (Client to Server)

enum WebSocketAction: String, CaseIterable {
    case ping = "ping"
    case joinRoom = "join_room"
    case leaveRoom = "leave_room"
    case startGame = "start_game"
    case startRound = "start_round"
    case submitCardChoice = "submit_card_choice"
    case submitVote = "submit_vote"
    case getGameState = "get_game_state"
    case getRoundCards = "get_round_cards"
    case getChoicesForVoting = "get_choices_for_voting"
    case startVoting = "start_voting"
    case endGame = "end_game"
    case getPlayersStatus = "get_players_status"
    case checkTimeouts = "check_timeouts"
    case getActionStatus = "get_action_status"
}

// MARK: - WebSocket Events (Server to Client)

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
    case cardChoiceSubmitted = "card_choice_submitted"
    case voteSubmitted = "vote_submitted"
    case gameStateUpdate = "game_state_update"
    case error = "error"
}

struct WebSocketEvent: Codable {
    let type: WebSocketEventType
    let data: [String: Any]
    let timestamp: String
    
    enum CodingKeys: String, CodingKey {
        case type
        case data
        case timestamp
    }
    
    init(type: WebSocketEventType, data: [String: Any] = [:], timestamp: String = ISO8601DateFormatter().string(from: Date())) {
        self.type = type
        self.data = data
        self.timestamp = timestamp
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

// MARK: - WebSocket Event Data Models

struct RoomStateChangedData: Codable {
    let room: RoomResponse
    let participants: [RoomParticipantResponse]
    let creator_nickname: String
    let can_start_game: Bool
}

struct GameStartedData: Codable {
    let game: GameResponse
    let players: [GamePlayerResponse]
    let first_round: RoundResponse?
}

struct RoundStartedData: Codable {
    let round: RoundResponse
    let situation: String
    let time_limit: TimeInterval
    let available_cards: [CardResponse]
}

struct VotingStartedData: Codable {
    let round: RoundResponse
    let choices: [CardChoiceResponse]
    let time_limit: TimeInterval
}

struct RoundEndedData: Codable {
    let round: RoundResponse
    let results: RoundResultResponse
    let next_round: RoundResponse?
}

struct GameEndedData: Codable {
    let game: GameResponse
    let winner: GamePlayerResponse?
    let final_scores: [PlayerScore]
    let total_rounds: Int
}

struct PlayerJoinedData: Codable {
    let participant: RoomParticipantResponse
    let room: RoomResponse
    let total_players: Int
}

struct PlayerLeftData: Codable {
    let user_id: Int
    let user_nickname: String
    let room: RoomResponse
    let total_players: Int
}

struct TimeoutWarningData: Codable {
    let round_id: Int
    let time_remaining: TimeInterval
    let warning_type: String // "choice" or "vote"
}

struct PlayerTimeoutData: Codable {
    let user_id: Int
    let user_nickname: String
    let round_id: Int
    let timeout_type: String // "choice" or "vote"
}

struct CardChoiceSubmittedData: Codable {
    let choice: CardChoiceResponse
    let total_choices: Int
    let expected_choices: Int
}

struct VoteSubmittedData: Codable {
    let vote: VoteResponse
    let total_votes: Int
    let expected_votes: Int
}

struct GameStateUpdateData: Codable {
    let game_state: GameState
    let time_remaining: TimeInterval?
}

struct WebSocketErrorData: Codable {
    let error_code: String
    let message: String
    let details: String?
}

// MARK: - WebSocket Connection Models

struct WebSocketConnectionInfo: Codable {
    let room_id: Int?
    let user_id: Int
    let token: String
    let connection_id: String
}

struct WebSocketStats: Codable {
    let total_connections: Int
    let active_rooms: Int
    let total_messages_sent: Int
    let total_messages_received: Int
    let average_latency: TimeInterval
}

// MARK: - WebSocket Message Builders

extension WebSocketMessage {
    static func ping() -> WebSocketMessage {
        return WebSocketMessage(action: WebSocketAction.ping.rawValue)
    }
    
    static func joinRoom(roomId: Int) -> WebSocketMessage {
        return WebSocketMessage(action: WebSocketAction.joinRoom.rawValue, data: ["room_id": roomId])
    }
    
    static func leaveRoom(roomId: Int) -> WebSocketMessage {
        return WebSocketMessage(action: WebSocketAction.leaveRoom.rawValue, data: ["room_id": roomId])
    }
    
    static func startGame(roomId: Int) -> WebSocketMessage {
        return WebSocketMessage(action: WebSocketAction.startGame.rawValue, data: ["room_id": roomId])
    }
    
    static func submitCardChoice(roundId: Int, cardId: String, isAnonymous: Bool) -> WebSocketMessage {
        return WebSocketMessage(action: WebSocketAction.submitCardChoice.rawValue, data: [
            "round_id": roundId,
            "card_id": cardId,
            "is_anonymous": isAnonymous
        ])
    }
    
    static func submitVote(roundId: Int, votedForUserId: Int) -> WebSocketMessage {
        return WebSocketMessage(action: WebSocketAction.submitVote.rawValue, data: [
            "round_id": roundId,
            "voted_for_user_id": votedForUserId
        ])
    }
    
    static func startVoting(roundId: Int) -> WebSocketMessage {
        return WebSocketMessage(action: WebSocketAction.startVoting.rawValue, data: ["round_id": roundId])
    }
    
    static func getGameState(roomId: Int) -> WebSocketMessage {
        return WebSocketMessage(action: WebSocketAction.getGameState.rawValue, data: ["room_id": roomId])
    }
}

// MARK: - Notification Names for WebSocket Events

extension Notification.Name {
    static let roomStateChanged = Notification.Name("roomStateChanged")
    static let gameStarted = Notification.Name("gameStarted")
    static let roundStarted = Notification.Name("roundStarted")
    static let votingStarted = Notification.Name("votingStarted")
    static let roundEnded = Notification.Name("roundEnded")
    static let gameEnded = Notification.Name("gameEnded")
    static let playerJoined = Notification.Name("playerJoined")
    static let playerLeft = Notification.Name("playerLeft")
    static let timeoutWarning = Notification.Name("timeoutWarning")
    static let playerTimeout = Notification.Name("playerTimeout")
    static let cardChoiceSubmitted = Notification.Name("cardChoiceSubmitted")
    static let voteSubmitted = Notification.Name("voteSubmitted")
    static let gameStateUpdate = Notification.Name("gameStateUpdate")
    static let websocketError = Notification.Name("websocketError")
} 