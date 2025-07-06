import Foundation

struct APIConfig {
    // Development URLs
    static let baseURL = "http://localhost:8000"
    static let wsURL = "ws://localhost:8000/ws"
    
    // Production URLs (uncomment when deploying)
    // static let baseURL = "https://your-domain.com"
    // static let wsURL = "wss://your-domain.com/ws"
    
    // API Endpoints
    struct Endpoints {
        // Authentication
        static let gameCenterAuth = "/api/v1/auth/login-game-center"
        
        // Users
        static let userProfile = "/api/v1/users/profile"
        static let updateProfile = "/api/v1/users/profile"
        
        // Cards
        static let cards = "/api/v1/cards"
        static let userCards = "/api/v1/users/cards"
        
        // Rooms
        static let rooms = "/api/v1/rooms"
        static let createRoom = "/api/v1/rooms"
        static let joinRoom = "/api/v1/rooms/{room_id}/join"
        static let leaveRoom = "/api/v1/rooms/{room_id}/leave"
        static let startGame = "/api/v1/rooms/{room_id}/start"
        
        // Health and Documentation
        static let health = "/health"
        static let docs = "/docs"
        static let openAPI = "/openapi.json"
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
    
    // HTTP Status Codes
    struct StatusCodes {
        static let ok = 200
        static let created = 201
        static let badRequest = 400
        static let unauthorized = 401
        static let forbidden = 403
        static let notFound = 404
        static let unprocessableEntity = 422
        static let tooManyRequests = 429
        static let internalServerError = 500
    }
    
    // Pagination
    struct Pagination {
        static let defaultPageSize = 20
        static let maxPageSize = 50
    }
    
    // Game Center
    struct GameCenter {
        static let minimumAge = 6
        static let tokenExpirationDays = 7
        static let tokenExpirationSeconds = 604800
    }
} 