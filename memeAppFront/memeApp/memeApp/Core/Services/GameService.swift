import Foundation
import os

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
        logger.debug("Fetching cards for game")
        
        do {
            let response: [UserCardResponse] = try await networkManager.makeRequest(
                endpoint: "\(APIConfig.Endpoints.games)/my-cards-for-game",
                method: .GET
            )
            logger.debug("Successfully fetched \(response.count) cards for game")
            return response
        } catch {
            logger.error("Failed to fetch cards for game: \(error.localizedDescription)")
            throw error
        }
    }
    
    func generateSituations() async throws -> [String] {
        logger.debug("Generating situations")
        
        do {
            let response: [String] = try await networkManager.makeRequest(
                endpoint: "\(APIConfig.Endpoints.games)/situations/generate",
                method: .POST
            )
            logger.debug("Successfully generated \(response.count) situations")
            return response
        } catch {
            logger.error("Failed to generate situations: \(error.localizedDescription)")
            throw error
        }
    }
    
    func getCurrentGame(roomId: Int) async throws -> Game? {
        logger.debug("Fetching current game for room: \(roomId)")
        
        do {
            let response: Game? = try await networkManager.makeRequest(
                endpoint: "\(APIConfig.Endpoints.games)/rooms/\(roomId)/current-game",
                method: .GET
            )
            logger.debug("Successfully fetched current game")
            return response
        } catch {
            logger.error("Failed to fetch current game: \(error.localizedDescription)")
            throw error
        }
    }
    
    func getGameDetails(gameId: Int) async throws -> Game {
        logger.debug("Fetching game details for ID: \(gameId)")
        
        do {
            let response: Game = try await networkManager.makeRequest(
                endpoint: "\(APIConfig.Endpoints.games)/\(gameId)",
                method: .GET
            )
            logger.debug("Successfully fetched game details")
            return response
        } catch {
            logger.error("Failed to fetch game details: \(error.localizedDescription)")
            throw error
        }
    }
    
    func startRound(gameId: Int) async throws -> Round {
        logger.debug("Starting round for game: \(gameId)")
        
        do {
            let response: Round = try await networkManager.makeRequest(
                endpoint: "\(APIConfig.Endpoints.games)/\(gameId)/rounds",
                method: .POST
            )
            logger.debug("Successfully started round")
            return response
        } catch {
            logger.error("Failed to start round: \(error.localizedDescription)")
            throw error
        }
    }
    
    func submitChoice(roundId: Int, cardId: Int) async throws {
        logger.debug("Submitting choice for round: \(roundId), card: \(cardId)")
        
        let choiceData: [String: Any] = [
            "card_id": cardId
        ]
        
        do {
            let _: [String: Any] = try await networkManager.makeRequest(
                endpoint: "\(APIConfig.Endpoints.games)/rounds/\(roundId)/choices",
                method: .POST,
                body: try? JSONSerialization.data(withJSONObject: choiceData)
            )
            logger.debug("Successfully submitted choice")
        } catch {
            logger.error("Failed to submit choice: \(error.localizedDescription)")
            throw error
        }
    }
    
    func startVoting(roundId: Int) async throws {
        logger.debug("Starting voting for round: \(roundId)")
        
        do {
            let _: [String: Any] = try await networkManager.makeRequest(
                endpoint: "\(APIConfig.Endpoints.games)/rounds/\(roundId)/voting/start",
                method: .POST
            )
            logger.debug("Successfully started voting")
        } catch {
            logger.error("Failed to start voting: \(error.localizedDescription)")
            throw error
        }
    }
    
    func submitVote(roundId: Int, choiceId: Int) async throws {
        logger.debug("Submitting vote for round: \(roundId), choice: \(choiceId)")
        
        let voteData: [String: Any] = [
            "choice_id": choiceId
        ]
        
        do {
            let _: [String: Any] = try await networkManager.makeRequest(
                endpoint: "\(APIConfig.Endpoints.games)/rounds/\(roundId)/votes",
                method: .POST,
                body: try? JSONSerialization.data(withJSONObject: voteData)
            )
            logger.debug("Successfully submitted vote")
        } catch {
            logger.error("Failed to submit vote: \(error.localizedDescription)")
            throw error
        }
    }
    
    func getRoundResults(roundId: Int) async throws -> Round {
        logger.debug("Fetching round results for ID: \(roundId)")
        
        do {
            let response: Round = try await networkManager.makeRequest(
                endpoint: "\(APIConfig.Endpoints.games)/rounds/\(roundId)/results",
                method: .GET
            )
            logger.debug("Successfully fetched round results")
            return response
        } catch {
            logger.error("Failed to fetch round results: \(error.localizedDescription)")
            throw error
        }
    }
    
    func getRoundChoices(roundId: Int) async throws -> [RoundChoice] {
        logger.debug("Fetching round choices for ID: \(roundId)")
        
        do {
            let response: [RoundChoice] = try await networkManager.makeRequest(
                endpoint: "\(APIConfig.Endpoints.games)/rounds/\(roundId)/choices",
                method: .GET
            )
            logger.debug("Successfully fetched \(response.count) round choices")
            return response
        } catch {
            logger.error("Failed to fetch round choices: \(error.localizedDescription)")
            throw error
        }
    }
    
    func endGame(gameId: Int) async throws {
        logger.debug("Ending game with ID: \(gameId)")
        
        do {
            let _: [String: Any] = try await networkManager.makeRequest(
                endpoint: "\(APIConfig.Endpoints.games)/\(gameId)/end",
                method: .POST
            )
            logger.debug("Successfully ended game")
        } catch {
            logger.error("Failed to end game: \(error.localizedDescription)")
            throw error
        }
    }
} 