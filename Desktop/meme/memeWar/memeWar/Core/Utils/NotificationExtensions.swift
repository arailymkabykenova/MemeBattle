//
//  NotificationExtensions.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import Foundation

extension Notification.Name {
    // WebSocket Events
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
    
    // Game Events
    static let situationGenerated = Notification.Name("situationGenerated")
    static let cardsLoaded = Notification.Name("cardsLoaded")
    static let choiceSubmitted = Notification.Name("choiceSubmitted")
    static let roundResults = Notification.Name("roundResults")
} 