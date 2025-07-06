//
//  RoomRepository.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import Foundation

protocol RoomRepositoryProtocol {
    func createRoom(request: CreateRoomRequest) async throws -> RoomResponse
    func getAvailableRooms() async throws -> [RoomResponse]
    func getMyRoom() async throws -> RoomResponse?
    func getRoomDetails(roomId: Int) async throws -> RoomDetailResponse
    func joinRoom(roomId: Int) async throws -> RoomResponse
    func joinByCode(code: String) async throws -> RoomResponse
    func quickMatch() async throws -> RoomResponse
    func leaveRoom(roomId: Int) async throws
    func startGame(roomId: Int) async throws -> GameResponse
    func getRoomStats() async throws -> RoomStatsResponse
}

class RoomRepository: RoomRepositoryProtocol {
    private let networkManager: NetworkManagerProtocol
    private let tokenManager: TokenManagerProtocol
    
    init(networkManager: NetworkManagerProtocol = NetworkManager.shared,
         tokenManager: TokenManagerProtocol = TokenManager.shared) {
        self.networkManager = networkManager
        self.tokenManager = tokenManager
    }
    
    func createRoom(request: CreateRoomRequest) async throws -> RoomResponse {
        let response: RoomResponse = try await networkManager.post(
            endpoint: APIConstants.Endpoints.createRoom,
            body: request
        )
        
        return response
    }
    
    func getAvailableRooms() async throws -> [RoomResponse] {
        let response: [RoomResponse] = try await networkManager.get(
            endpoint: APIConstants.Endpoints.availableRooms
        )
        
        return response
    }
    
    func getMyRoom() async throws -> RoomResponse? {
        let response: RoomResponse? = try await networkManager.get(
            endpoint: APIConstants.Endpoints.myRoom
        )
        
        return response
    }
    
    func getRoomDetails(roomId: Int) async throws -> RoomDetailResponse {
        let endpoint = APIConstants.Endpoints.roomDetails.replacingOccurrences(of: "{room_id}", with: "\(roomId)")
        let response: RoomDetailResponse = try await networkManager.get(endpoint: endpoint)
        
        return response
    }
    
    func joinRoom(roomId: Int) async throws -> RoomResponse {
        let endpoint = APIConstants.Endpoints.joinRoom.replacingOccurrences(of: "{room_id}", with: "\(roomId)")
        let response: RoomResponse = try await networkManager.post(
            endpoint: endpoint,
            body: EmptyRequest()
        )
        
        return response
    }
    
    func joinByCode(code: String) async throws -> RoomResponse {
        let request = JoinByCodeRequest(room_code: code)
        let response: RoomResponse = try await networkManager.post(
            endpoint: APIConstants.Endpoints.joinByCode,
            body: request
        )
        
        return response
    }
    
    func quickMatch() async throws -> RoomResponse {
        let response: RoomResponse = try await networkManager.post(
            endpoint: APIConstants.Endpoints.quickMatch,
            body: EmptyRequest()
        )
        
        return response
    }
    
    func leaveRoom(roomId: Int) async throws {
        let endpoint = APIConstants.Endpoints.leaveRoom.replacingOccurrences(of: "{room_id}", with: "\(roomId)")
        try await networkManager.post(
            endpoint: endpoint,
            body: EmptyRequest()
        )
    }
    
    func startGame(roomId: Int) async throws -> GameResponse {
        let endpoint = APIConstants.Endpoints.startGame.replacingOccurrences(of: "{room_id}", with: "\(roomId)")
        let response: GameResponse = try await networkManager.post(
            endpoint: endpoint,
            body: EmptyRequest()
        )
        
        return response
    }
    
    func getRoomStats() async throws -> RoomStatsResponse {
        let response: RoomStatsResponse = try await networkManager.get(
            endpoint: APIConstants.Endpoints.roomStats
        )
        
        return response
    }
}

// MARK: - Room Requests

struct JoinByCodeRequest: Codable {
    let room_code: String
} 