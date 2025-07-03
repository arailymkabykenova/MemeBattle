import Foundation

// MARK: - Game State Models
struct Game: Codable, Identifiable {
    let id: Int
    let room_id: Int
    let status: String
    let current_round: Int
    let total_rounds: Int
    let created_at: String
    let players: [GamePlayer]
    let current_situation: GameSituation?
    
    var gameStatus: GameStatus {
        GameStatus(rawValue: status) ?? .waiting
    }
}

struct GamePlayer: Codable, Identifiable {
    let id: Int
    let user_id: Int
    let nickname: String
    let score: Int
    let cards_played: Int
    let is_current_player: Bool
    let is_ready: Bool
}

struct GameSituation: Codable {
    let id: Int
    let description: String
    let category: String
    let difficulty: String
    let time_limit: Int
}

// MARK: - WebSocket Message Models
struct WebSocketMessage: Codable {
    let action: String
    let data: [String: AnyCodable]
    let timestamp: String?
    let room_id: Int?
    
    enum CodingKeys: String, CodingKey {
        case action, data, timestamp, room_id
    }
}

struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}

// MARK: - Game Status Enums
enum GameStatus: String, CaseIterable, Codable {
    case waiting = "waiting"
    case playing = "playing"
    case voting = "voting"
    case finished = "finished"
    
    var displayName: String {
        switch self {
        case .waiting: return "Ожидание"
        case .playing: return "Игра"
        case .voting: return "Голосование"
        case .finished: return "Завершена"
        }
    }
}

// MARK: - WebSocket Actions
enum WebSocketAction: String, CaseIterable {
    // Client to Server
    case joinRoom = "join_room"
    case leaveRoom = "leave_room"
    case playCard = "play_card"
    case submitVote = "submit_vote"
    case ping = "ping"
    
    // Server to Client
    case playerJoined = "player_joined"
    case playerLeft = "player_left"
    case gameStarted = "game_started"
    case roundStarted = "round_started"
    case cardPlayed = "card_played"
    case votingStarted = "voting_started"
    case voteSubmitted = "vote_submitted"
    case roundEnded = "round_ended"
    case gameEnded = "game_ended"
    case error = "error"
    case timerUpdate = "timer_update"
    case connectionLost = "connection_lost"
    case pong = "pong"
} 