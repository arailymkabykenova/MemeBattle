import Foundation
import GameKit

struct APIConfig {
    static let baseURL = "http://172.20.10.11:8000"
    static let wsURL = "ws://172.20.10.11:8000/websocket/ws"
    
    // Production URLs (заменить при деплое)
    // static let baseURL = "https://your-domain.com"
    // static let wsURL = "wss://your-domain.com/ws"
    
    // API Endpoints
    struct Endpoints {
        static let auth = "/auth"
        static let users = "/users"
        static let rooms = "/rooms"
        static let games = "/games"
        static let cards = "/cards"
        static let health = "/health"
    }
    
    // Headers
    struct Headers {
        static let contentType = "Content-Type"
        static let authorization = "Authorization"
        static let userAgent = "User-Agent"
        static let acceptLanguage = "Accept-Language"
        
        static let contentTypeValue = "application/json"
        static let userAgentValue = "MemeGame-iOS/1.0.0"
        static let acceptLanguageValue = "ru-RU, en-US"
    }
} 