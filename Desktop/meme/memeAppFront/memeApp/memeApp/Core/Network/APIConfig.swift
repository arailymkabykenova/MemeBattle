import Foundation

struct APIConfig {
    // MARK: - Base URLs
    // Для Docker используем IP-адрес хоста (вашего устройства)
    // Замените на ваш реальный IP-адрес
    static let baseURL = "http://172.20.10.11:8000"  // Ваш IP-адрес
    static let wsURL = "ws://172.20.10.11:8000/ws"   // Ваш IP-адрес
    
    // Альтернативные варианты (раскомментируйте нужный):
    // static let baseURL = "http://192.168.1.100:8000"  // Другой IP
    // static let baseURL = "http://10.0.0.50:8000"      // Еще один IP
    
    // Для разработки на симуляторе можно использовать:
    // static let baseURL = "http://localhost:8000"
    // static let wsURL = "ws://localhost:8000/ws"
    
    // MARK: - API Endpoints
    struct Endpoints {
        // Auth endpoints
        static let auth = "/auth"
        static let users = "/users"
        
        // Cards endpoints
        static let cards = "/cards"
        
        // Rooms endpoints
        static let rooms = "/rooms"
        
        // Game endpoints
        static let game = "/game"
        static let games = "/games"
        static let rounds = "/rounds"
        static let choices = "/choices"
        static let votes = "/votes"
    }
    
    // MARK: - Headers
    static let defaultHeaders: [String: String] = [
        "Content-Type": "application/json",
        "User-Agent": "MemeGame-iOS/1.0.0",
        "Accept": "application/json",
        "Accept-Language": "ru-RU, en-US"
    ]
    
    // MARK: - Timeouts
    static let requestTimeout: TimeInterval = 30.0
    static let websocketTimeout: TimeInterval = 10.0
    
    // MARK: - Retry Configuration
    static let maxRetries = 3
    static let retryDelay: TimeInterval = 2.0
    
    // MARK: - Pagination
    static let defaultPageSize = 20
    static let maxPageSize = 50
    
    // MARK: - Validation
    struct Validation {
        static let minNicknameLength = 3
        static let maxNicknameLength = 20
        static let minAge = 6
        static let maxAge = 100
        static let nicknameRegex = "^[a-zA-Zа-яА-Я0-9_]+$"
    }
    
    // MARK: - Game Configuration
    struct Game {
        static let minPlayers = 2
        static let maxPlayers = 8
        static let roundDuration: TimeInterval = 60.0
        static let votingDuration: TimeInterval = 30.0
        static let cardsPerRound = 3
    }
    
    // MARK: - Age Groups
    enum AgeGroup: String, CaseIterable {
        case child = "child"
        case teen = "teen"
        case adult = "adult"
        case mixed = "mixed"
        
        var displayName: String {
            switch self {
            case .child: return "Дети (6-12 лет)"
            case .teen: return "Подростки (13-17 лет)"
            case .adult: return "Взрослые (18+)"
            case .mixed: return "Смешанная группа"
            }
        }
        
        var minAge: Int {
            switch self {
            case .child: return 6
            case .teen: return 13
            case .adult: return 18
            case .mixed: return 6
            }
        }
        
        var maxAge: Int {
            switch self {
            case .child: return 12
            case .teen: return 17
            case .adult: return 999
            case .mixed: return 999
            }
        }
    }
    
    // MARK: - Card Types
    enum CardType: String, CaseIterable {
        case starter = "starter"
        case standard = "standard"
        case unique = "unique"
        
        var displayName: String {
            switch self {
            case .starter: return "Стартовые"
            case .standard: return "Обычные"
            case .unique: return "Уникальные"
            }
        }
        
        var icon: String {
            switch self {
            case .starter: return "star.fill"
            case .standard: return "rectangle.stack.fill"
            case .unique: return "crown.fill"
            }
        }
        
        var color: String {
            switch self {
            case .starter: return "#FFD700" // Gold
            case .standard: return "#007AFF" // Blue
            case .unique: return "#AF52DE" // Purple
            }
        }
    }
    
    // MARK: - Error Messages
    struct ErrorMessages {
        static let networkError = "Ошибка сети. Проверьте подключение к интернету."
        static let serverError = "Ошибка сервера. Попробуйте позже."
        static let unauthorized = "Необходима авторизация."
        static let forbidden = "Доступ запрещен."
        static let notFound = "Ресурс не найден."
        static let validationError = "Ошибка валидации данных."
        static let rateLimited = "Слишком много запросов. Попробуйте позже."
        static let unknown = "Неизвестная ошибка."
    }
    
    // MARK: - Debug Configuration
    #if DEBUG
    static let enableLogging = true
    static let enableNetworkLogging = true
    static let enableWebSocketLogging = true
    #else
    static let enableLogging = false
    static let enableNetworkLogging = false
    static let enableWebSocketLogging = false
    #endif
}

// MARK: - Extensions
extension APIConfig {
    static func getAuthHeaders(token: String) -> [String: String] {
        var headers = defaultHeaders
        headers["Authorization"] = "Bearer \(token)"
        return headers
    }
    
    static func getWebSocketURL(token: String, roomId: Int? = nil) -> String {
        var url = "\(wsURL)?token=\(token)"
        if let roomId = roomId {
            url += "&room_id=\(roomId)"
        }
        return url
    }
    
    static func validateNickname(_ nickname: String) -> Bool {
        let regex = try! NSRegularExpression(pattern: Validation.nicknameRegex)
        let range = NSRange(location: 0, length: nickname.count)
        let matches = regex.firstMatch(in: nickname, range: range) != nil
        
        return nickname.count >= Validation.minNicknameLength &&
               nickname.count <= Validation.maxNicknameLength &&
               matches
    }
    
    static func validateAge(_ age: Int) -> Bool {
        return age >= Validation.minAge && age <= Validation.maxAge
    }
    
    static func getAgeGroup(for age: Int) -> AgeGroup {
        switch age {
        case 6...12:
            return .child
        case 13...17:
            return .teen
        case 18...:
            return .adult
        default:
            return .mixed
        }
    }
} 