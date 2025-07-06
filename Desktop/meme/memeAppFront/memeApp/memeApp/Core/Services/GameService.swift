import Foundation
import os

// MARK: - Request Models
struct ChoiceRequest: Codable {
    let card_id: Int
}

struct VoteRequest: Codable {
    let choice_id: Int
}

protocol GameServiceProtocol {
    func getMyCardsForGame() async throws -> [UserCardResponse]
    func generateSituations() async throws -> [String]
    func getCurrentGame(roomId: Int) async throws -> Game?
    func getGameDetails(gameId: Int) async throws -> Game
    func startRound(gameId: Int) async throws -> Round
    func submitChoice(roundId: Int, cardId: Int) async throws
    func startVoting(roundId: Int) async throws
    func submitVote(roundId: Int, choiceId: Int) async throws
    func getRoundResults(roundId: Int) async throws -> Round
    func getRoundChoices(roundId: Int) async throws -> [RoundChoice]
    func endGame(gameId: Int) async throws
}

class GameService: GameServiceProtocol {
    private let networkManager = NetworkManager.shared
    private let logger = Logger(subsystem: "com.memegame.app", category: "game-service")
    
    func getMyCardsForGame() async throws -> [UserCardResponse] {
        logger.debug("Fetching cards for game - TEMPORARILY DISABLED")
        return []
    }
    
    func generateSituations() async throws -> [String] {
        logger.debug("Generating situations - TEMPORARILY DISABLED")
        return []
    }
    
    func getCurrentGame(roomId: Int) async throws -> Game? {
        logger.debug("Getting current game - TEMPORARILY DISABLED")
        return nil
    }
    
    func getGameDetails(gameId: Int) async throws -> Game {
        logger.debug("Getting game details - TEMPORARILY DISABLED")
        throw NetworkError.notFound
    }
    
    func startRound(gameId: Int) async throws -> Round {
        logger.debug("Starting round - TEMPORARILY DISABLED")
        throw NetworkError.notFound
    }
    
    func submitChoice(roundId: Int, cardId: Int) async throws {
        logger.debug("Submitting choice - TEMPORARILY DISABLED")
    }
    
    func startVoting(roundId: Int) async throws {
        logger.debug("Starting voting - TEMPORARILY DISABLED")
    }
    
    func submitVote(roundId: Int, choiceId: Int) async throws {
        logger.debug("Submitting vote - TEMPORARILY DISABLED")
    }
    
    func getRoundResults(roundId: Int) async throws -> Round {
        logger.debug("Getting round results - TEMPORARILY DISABLED")
        throw NetworkError.notFound
    }
    
    func getRoundChoices(roundId: Int) async throws -> [RoundChoice] {
        logger.debug("Getting round choices - TEMPORARILY DISABLED")
        return []
    }
    
    func endGame(gameId: Int) async throws {
        logger.debug("Ending game - TEMPORARILY DISABLED")
    }
} 