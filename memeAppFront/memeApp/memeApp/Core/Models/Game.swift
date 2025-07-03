import Foundation

// MARK: - Game Models

struct Game: Codable, Identifiable {
    let id: Int
    let room_id: Int
    let status: GameStatus
    let current_round: Int?
    let total_rounds: Int
    let created_at: String
    let started_at: String?
    let ended_at: String?
    let players: [GamePlayer]
    let winner_id: Int?
}

enum GameStatus: String, Codable {
    case waiting = "waiting"
    case playing = "playing"
    case finished = "finished"
    case cancelled = "cancelled"
}

struct GamePlayer: Codable, Identifiable {
    let id: Int
    let user_id: Int
    let nickname: String
    let score: Int
    let cards_count: Int
    let is_ready: Bool
    let joined_at: String
}

struct Round: Codable, Identifiable {
    let id: Int
    let game_id: Int
    let round_number: Int
    let situation: String
    let status: RoundStatus
    let created_at: String
    let started_at: String?
    let ended_at: String?
    var choices: [RoundChoice]
    var votes: [RoundVote]
    let winner_id: Int?
}

enum RoundStatus: String, Codable {
    case waiting = "waiting"
    case choosing = "choosing"
    case voting = "voting"
    case finished = "finished"
}

struct RoundChoice: Codable, Identifiable {
    let id: Int
    let round_id: Int
    let player_id: Int
    let card_id: Int
    let card_name: String
    let card_image_url: String
    let created_at: String
}

struct RoundVote: Codable, Identifiable {
    let id: Int
    let round_id: Int
    let voter_id: Int
    let choice_id: Int
    let created_at: String
}

// MARK: - WebSocket Models

struct WebSocketMessage: Codable {
    let action: String
    let data: [String: AnyCodable]
    let timestamp: String?
    let room_id: Int?
}

struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable cannot decode value")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self.value {
        case is NSNull:
            try container.encodeNil()
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
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable cannot encode value")
            throw EncodingError.invalidValue(self.value, context)
        }
    }
}

// MARK: - WebSocket Events

enum WebSocketEvent {
    case playerJoined(PlayerJoinedData)
    case playerLeft(PlayerLeftData)
    case gameStarted(GameStartedData)
    case roundStarted(RoundStartedData)
    case cardPlayed(CardPlayedData)
    case votingStarted(VotingStartedData)
    case voteSubmitted(VoteSubmittedData)
    case roundEnded(RoundEndedData)
    case gameEnded(GameEndedData)
    case error(ErrorData)
    case timerUpdate(TimerUpdateData)
    case connectionLost
}

struct PlayerJoinedData: Codable {
    let player: GamePlayer
    let room_id: Int
}

struct PlayerLeftData: Codable {
    let player_id: Int
    let room_id: Int
}

struct GameStartedData: Codable {
    let game: Game
    let room_id: Int
}

struct RoundStartedData: Codable {
    let round: Round
    let room_id: Int
    let time_limit: Int
}

struct CardPlayedData: Codable {
    let choice: RoundChoice
    let room_id: Int
    let player_id: Int
}

struct VotingStartedData: Codable {
    let choices: [RoundChoice]
    let room_id: Int
    let time_limit: Int
}

struct VoteSubmittedData: Codable {
    let vote: RoundVote
    let room_id: Int
    let voter_id: Int
}

struct RoundEndedData: Codable {
    let round: Round
    let winner: GamePlayer?
    let room_id: Int
}

struct GameEndedData: Codable {
    let game: Game
    let winner: GamePlayer?
    let room_id: Int
}

struct ErrorData: Codable {
    let message: String
    let code: String?
}

struct TimerUpdateData: Codable {
    let time_remaining: Int
    let room_id: Int
} 