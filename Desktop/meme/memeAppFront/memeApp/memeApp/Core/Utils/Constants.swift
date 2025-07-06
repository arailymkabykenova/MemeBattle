import Foundation
import SwiftUI

struct Constants {
    // App Info
    static let appName = "Мем Карточная Игра"
    static let appVersion = "1.0.0"
    static let buildNumber = "1"
    
    // UI Constants
    struct UI {
        static let cornerRadius: CGFloat = 12
        static let smallCornerRadius: CGFloat = 8
        static let largeCornerRadius: CGFloat = 20
        
        static let padding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let largePadding: CGFloat = 24
        
        static let cardAspectRatio: CGFloat = 1.4
        static let cardWidth: CGFloat = 120
        static let cardHeight: CGFloat = 168
        
        static let animationDuration: Double = 0.3
        static let springAnimation = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.8)
    }
    
    // Game Constants
    struct Game {
        static let minPlayers = 2
        static let maxPlayers = 6
        static let defaultMaxPlayers = 4
        
        static let roundDuration: TimeInterval = 60 // 60 seconds
        static let votingDuration: TimeInterval = 30 // 30 seconds
        
        static let maxCardsInHand = 5
        static let maxRounds = 10
    }
    
    // Validation Constants
    struct Validation {
        static let minNicknameLength = 3
        static let maxNicknameLength = 20
        static let minAge = 6
        static let maxAge = 100
        
        static let nicknameRegex = "^[a-zA-Zа-яА-Я0-9_]+$"
    }
    
    // Animation Constants
    struct Animation {
        static let cardDealDelay: Double = 0.1
        static let cardFlipDuration: Double = 0.5
        static let cardGlowDuration: Double = 2.0
        static let backgroundShiftDuration: Double = 10.0
    }
    
    // Error Messages
    struct ErrorMessages {
        static let networkError = "Ошибка сети. Проверьте подключение к интернету."
        static let authenticationError = "Ошибка аутентификации. Войдите в Game Center."
        static let gameCenterNotAvailable = "Game Center недоступен."
        static let roomFull = "Комната заполнена."
        static let roomNotFound = "Комната не найдена."
        static let invalidRoomCode = "Неверный код комнаты."
        static let ageRestriction = "Возрастное ограничение не позволяет присоединиться к этой комнате."
        static let gameInProgress = "Игра уже в процессе."
        static let unknownError = "Произошла неизвестная ошибка."
    }
    
    // Success Messages
    struct SuccessMessages {
        static let roomCreated = "Комната создана!"
        static let roomJoined = "Вы присоединились к комнате!"
        static let cardPlayed = "Карта сыграна!"
        static let voteSubmitted = "Голос подан!"
        static let gameStarted = "Игра началась!"
    }
} 