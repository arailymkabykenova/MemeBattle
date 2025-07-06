# 📱 iOS Models для интеграции с бэком

## 🔐 Auth Models

```swift
// MARK: - Auth Models
struct DeviceAuthRequest: Codable {
    let device_id: String
}

struct AuthResponse: Codable {
    let access_token: String
    let token_type: String
    let user: User
    let is_new_user: Bool
}

struct UserProfileCreate: Codable {
    let nickname: String
    let birth_date: String // "2000-01-01"
    let gender: String // "male", "female", "other"
}

struct UserProfileResponse: Codable {
    let id: Int
    let game_center_player_id: String?
    let nickname: String
    let birth_date: String
    let gender: String
    let rating: Double
    let created_at: String
    let age: Int
    let cards_count: Int
    let rank: Int
}

struct User: Codable {
    let id: Int
    let device_id: String
    let nickname: String?
    let birth_date: String?
    let gender: String?
    let rating: Double
    let created_at: String
    let is_profile_complete: Bool
    
    var age: Int {
        guard let birthDate = birth_date else { return 0 }
        // Вычисление возраста из birth_date
        return 0 // TODO: реализовать вычисление
    }
}
```

## 🏠 Room Models

```swift
// MARK: - Room Models
struct RoomCreateRequest: Codable {
    let max_players: Int
    let is_public: Bool
    let generate_code: Bool
}

struct RoomResponse: Codable {
    let id: Int
    let creator_id: Int
    let max_players: Int
    let status: String // "waiting", "playing", "finished"
    let room_code: String?
    let is_public: Bool
    let created_at: String
    let current_players: Int
}

struct RoomDetailResponse: Codable {
    let id: Int
    let creator_id: Int
    let max_players: Int
    let status: String
    let room_code: String?
    let is_public: Bool
    let age_group: String
    let created_at: String
    let current_players: Int
    let participants: [RoomParticipantResponse]
}

struct RoomParticipantResponse: Codable {
    let user_id: Int
    let nickname: String
    let joined_at: String
    let status: String // "active", "inactive"
}

struct RoomJoinByCodeRequest: Codable {
    let room_code: String
}

struct QuickMatchRequest: Codable {
    let max_players: Int
}

struct QuickMatchResponse: Codable {
    let room: RoomResponse
    let joined: Bool
}
```

## 🎮 Game Models

```swift
// MARK: - Game Models
struct GameStartResponse: Codable {
    let success: Bool
    let game_id: Int
    let message: String
}

struct GameResponse: Codable {
    let id: Int
    let room_id: Int
    let status: String // "starting", "card_selection", "voting", "round_results", "finished"
    let current_round: Int
    let winner_id: Int?
    let created_at: String
    let finished_at: String?
}

struct RoundStartResponse: Codable {
    let success: Bool
    let round: GameRoundResponse
}

struct GameRoundResponse: Codable {
    let id: Int
    let round_number: Int
    let situation_text: String
    let duration_seconds: Int
    let started_at: String
}

struct CardChoiceRequest: Codable {
    let card_type: String
    let card_number: Int
}

struct CardChoiceResponse: Codable {
    let success: Bool
    let choice: PlayerChoice
}

struct PlayerChoice: Codable {
    let id: Int
    let card_type: String
    let card_number: Int
    let submitted_at: String
}

struct VoteRequest: Codable {
    let choice_id: Int
}

struct VoteResponse: Codable {
    let success: Bool
    let vote: Vote
}

struct Vote: Codable {
    let id: Int
    let choice_id: Int
    let created_at: String
}

struct RoundResultResponse: Codable {
    let round_id: Int
    let round_number: Int
    let situation_text: String
    let winner_choice: PlayerChoiceResponse?
    let all_choices: [PlayerChoiceResponse]
    let votes: [VoteResponse]
    let next_round_starts_in: Int
}

struct PlayerChoiceResponse: Codable {
    let id: Int
    let user_id: Int
    let user_nickname: String
    let card_type: String
    let card_number: Int
    let card_url: String?
    let submitted_at: String
    let vote_count: Int
}

struct VoteResponse: Codable {
    let id: Int
    let voter_id: Int
    let voter_nickname: String
    let choice_id: Int
    let created_at: String
}

struct GameStateResponse: Codable {
    let game_id: Int
    let room_id: Int
    let status: String
    let current_round: Int
    let players: [GamePlayer]
    let current_round_data: GameRoundResponse?
}

struct GamePlayer: Codable {
    let user_id: Int
    let nickname: String
    let is_connected: Bool
    let has_chosen_card: Bool
    let has_voted: Bool
}
```

## 🃏 Card Models

```swift
// MARK: - Card Models
struct UserCardsResponse: Codable {
    let starter_cards: [UserCard]
    let standard_cards: [UserCard]
    let unique_cards: [UserCard]
    let total_cards: Int
}

struct UserCard: Codable {
    let user_id: Int
    let card_type: String
    let card_number: Int
    let obtained_at: String
    let card_url: String?
}

struct CardForGame: Codable {
    let card_type: String
    let card_number: Int
    let card_url: String?
}

struct AssignStarterCardsResponse: Codable {
    let message: String
    let cards_assigned: Int
    let cards: [CardResponse]
}

struct CardResponse: Codable {
    let id: String
    let name: String
    let image_url: String
    let card_type: String
    let description: String
    let created_at: String
    let is_starter_card: Bool
    let is_standard_card: Bool
    let is_unique_card: Bool
}

struct CardStatsResponse: Codable {
    let total_cards: Int
    let cards_by_type: [String: Int]
    let card_types: [String]
    let system_ready: Bool
    let azure_connected: Bool
}
```

## 🏆 Rating Models

```swift
// MARK: - Rating Models
struct LeaderboardResponse: Codable {
    let leaderboard: [LeaderboardEntry]
}

struct LeaderboardEntry: Codable {
    let rank: Int
    let user_id: Int
    let nickname: String
    let rating: Double
    let games_played: Int
    let games_won: Int
    let win_rate: Double
}

struct UserRankResponse: Codable {
    let rank: Int
}

struct UserStatsResponse: Codable {
    let total_cards: Int
    let rating: Double
    let rank: Int
    let profile_complete: Bool
    let created_at: String?
}
```

## 🔌 WebSocket Models

```swift
// MARK: - WebSocket Models
struct WebSocketMessage: Codable {
    let action: String
    let data: [String: Any]
    
    enum CodingKeys: String, CodingKey {
        case action
        case data
    }
    
    init(action: String, data: [String: Any]) {
        self.action = action
        self.data = data
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        action = try container.decode(String.self, forKey: .action)
        data = try container.decode([String: Any].self, forKey: .data)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(action, forKey: .action)
        try container.encode(data, forKey: .data)
    }
}

struct WebSocketResponse: Codable {
    let success: Bool
    let type: String?
    let message: String?
    let data: [String: Any]?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case type
        case message
        case data
        case error
    }
    
    init(success: Bool, type: String? = nil, message: String? = nil, data: [String: Any]? = nil, error: String? = nil) {
        self.success = success
        self.type = type
        self.message = message
        self.data = data
        self.error = error
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decode(Bool.self, forKey: .success)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        data = try container.decodeIfPresent([String: Any].self, forKey: .data)
        error = try container.decodeIfPresent(String.self, forKey: .error)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(success, forKey: .success)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encodeIfPresent(message, forKey: .message)
        try container.encodeIfPresent(data, forKey: .data)
        try container.encodeIfPresent(error, forKey: .error)
    }
}
```

## 🚨 Error Models

```swift
// MARK: - Error Models
struct APIErrorResponse: Codable {
    let detail: String
    let code: String?
}

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case badRequest
    case unauthorized
    case forbidden
    case notFound
    case conflict
    case validationError
    case rateLimited
    case serverError
    case unknown
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Неверный URL"
        case .invalidResponse:
            return "Неверный ответ сервера"
        case .badRequest:
            return "Неверный запрос"
        case .unauthorized:
            return "Не авторизован"
        case .forbidden:
            return "Доступ запрещен"
        case .notFound:
            return "Ресурс не найден"
        case .conflict:
            return "Конфликт"
        case .validationError:
            return "Ошибка валидации"
        case .rateLimited:
            return "Слишком много запросов"
        case .serverError:
            return "Ошибка сервера"
        case .unknown:
            return "Неизвестная ошибка"
        case .apiError(let message):
            return message
        }
    }
}

enum AuthError: Error, LocalizedError {
    case deviceIdGenerationFailed
    case networkError
    case serverError
    case invalidResponse
    case tokenExpired
    
    var errorDescription: String? {
        switch self {
        case .deviceIdGenerationFailed:
            return "Не удалось создать идентификатор устройства"
        case .networkError:
            return "Ошибка сети"
        case .serverError:
            return "Ошибка сервера"
        case .invalidResponse:
            return "Неверный ответ сервера"
        case .tokenExpired:
            return "Токен истёк"
        }
    }
}
```

## 📋 Enums

```swift
// MARK: - Enums
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

enum Gender: String, CaseIterable {
    case male = "male"
    case female = "female"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .male:
            return "Мужской"
        case .female:
            return "Женский"
        case .other:
            return "Другой"
        }
    }
}

enum RoomStatus: String {
    case waiting = "waiting"
    case playing = "playing"
    case finished = "finished"
}

enum GameStatus: String {
    case starting = "starting"
    case cardSelection = "card_selection"
    case voting = "voting"
    case roundResults = "round_results"
    case finished = "finished"
}

enum ParticipantStatus: String {
    case active = "active"
    case inactive = "inactive"
}
```

## 🔧 Utils

```swift
// MARK: - Utils
extension Date {
    func toISOString() -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
    
    static func fromISOString(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: string)
    }
}

extension String {
    func toDate() -> Date? {
        return Date.fromISOString(self)
    }
}

// MARK: - Codable Extensions
extension KeyedDecodingContainer {
    func decode(_ type: [String: Any].Type, forKey key: K) throws -> [String: Any] {
        let value = try decode(AnyCodable.self, forKey: key)
        return value.value as? [String: Any] ?? [:]
    }
}

extension KeyedEncodingContainer {
    mutating func encode(_ value: [String: Any], forKey key: K) throws {
        try encode(AnyCodable(value), forKey: key)
    }
}

struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
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
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable cannot decode value")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
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
            throw EncodingError.invalidValue(value, context)
        }
    }
}
```

## 📝 Примечания по использованию

1. **Все модели** соответствуют структуре ответов бэка
2. **Даты** передаются в формате ISO 8601 строк
3. **Enums** используются для типизации статусов
4. **AnyCodable** позволяет работать с динамическими JSON объектами
5. **Обработка ошибок** централизована через NetworkError и AuthError

## 🚀 Интеграция

1. Скопируйте все модели в соответствующие файлы iOS проекта
2. Убедитесь что все типы данных соответствуют
3. Используйте эти модели в NetworkManager и сервисах
4. Добавьте валидацию данных при необходимости 