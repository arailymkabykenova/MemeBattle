//
//  Constants.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import Foundation
import SwiftUI

// MARK: - App Constants

struct AppConstants {
    // Padding
    static let smallPadding: CGFloat = 8
    static let padding: CGFloat = 16
    static let largePadding: CGFloat = 24
    
    // Corner Radius
    static let smallCornerRadius: CGFloat = 8
    static let cornerRadius: CGFloat = 12
    static let largeCornerRadius: CGFloat = 16
    
    // Animation
    static let defaultAnimation: Animation = .easeInOut(duration: 0.3)
    static let fastAnimation: Animation = .easeInOut(duration: 0.15)
    
    // Timeouts
    static let networkTimeout: TimeInterval = 30
    static let websocketTimeout: TimeInterval = 10
}

// MARK: - API Constants

struct APIConstants {
    static let baseURL = "http://localhost:8000"
    static let wsBaseURL = "ws://localhost:8000"
    
    struct Endpoints {
        // Auth
        static let deviceAuth = "/auth/device"
        static let completeProfile = "/auth/complete-profile"
        static let me = "/auth/me"
        static let logout = "/auth/logout"
        
        // Cards
        static let allCards = "/cards"
        static let assignStarterCards = "/cards/assign-starter-cards"
        static let myCards = "/cards/my-cards"
        static let forGameRound = "/cards/for-game-round"
        static let cardsByType = "/cards/by-type"
        static let azureStatus = "/cards/azure/status"
        static let azureLoadByType = "/cards/azure/load"
        static let azureLoadAll = "/cards/azure/load-all"
        static let cardStatistics = "/cards/statistics"
        static let adminCreateBatch = "/cards/admin/create-batch"
        static let awardWinnerCard = "/cards/award-winner-card"
        
        // Users
        static let leaderboard = "/users"
        static let checkNickname = "/users/check-nickname"
        static let myStats = "/users/me/stats"
        static let getUserById = "/users"
        static let updateProfile = "/users/me"
        static let updateRating = "/users/{user_id}/rating"
        static let getUserRank = "/users/{user_id}/rank"
        
        // Rooms
        static let createRoom = "/rooms"
        static let availableRooms = "/rooms/available"
        static let myRoom = "/rooms/my-room"
        static let roomDetails = "/rooms/{room_id}"
        static let joinRoom = "/rooms/{room_id}/join"
        static let joinByCode = "/rooms/join-by-code"
        static let quickMatch = "/rooms/quick-match"
        static let leaveRoom = "/rooms/{room_id}/leave"
        static let startGame = "/rooms/{room_id}/start-game"
        static let roomStats = "/rooms/stats/summary"
        
        // Games
        static let myCardsForGame = "/games/my-cards-for-game"
        static let generateSituations = "/games/situations/generate"
        static let currentGame = "/games/rooms/{room_id}/current-game"
        static let gameDetails = "/games/{game_id}"
        static let createRound = "/games/{game_id}/rounds"
        static let submitChoice = "/games/rounds/{round_id}/choices"
        static let startVoting = "/games/rounds/{round_id}/voting/start"
        static let submitVote = "/games/rounds/{round_id}/votes"
        static let roundResults = "/games/rounds/{round_id}/results"
        static let roundChoices = "/games/rounds/{round_id}/choices"
        static let endGame = "/games/{game_id}/end"
        static let pingRoom = "/games/rooms/{room_id}/ping"
        static let playersStatus = "/games/rooms/{room_id}/players-status"
        static let checkTimeouts = "/games/rooms/{room_id}/check-timeouts"
        static let actionStatus = "/games/rounds/{round_id}/action-status"
        
        // WebSocket
        static let websocket = "/websocket/ws"
        static let wsStats = "/websocket/ws/stats"
        static let wsBroadcast = "/websocket/ws/broadcast/{room_id}"
    }
}

// MARK: - Color Extensions

extension Color {
    static let customBackground = Color(.systemBackground)
    static let customSecondaryBackground = Color(.secondarySystemBackground)
    static let customTertiaryBackground = Color(.tertiarySystemBackground)
    
    static let customLabel = Color(.label)
    static let customSecondaryLabel = Color(.secondaryLabel)
    static let customTertiaryLabel = Color(.tertiaryLabel)
    
    static let customSystemGray = Color(.systemGray)
    static let customSystemGray2 = Color(.systemGray2)
    static let customSystemGray3 = Color(.systemGray3)
    static let customSystemGray4 = Color(.systemGray4)
    static let customSystemGray5 = Color(.systemGray5)
    static let customSystemGray6 = Color(.systemGray6)
} 