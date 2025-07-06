//
//  RoomRepository.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import Foundation
import Combine

protocol RoomRepositoryProtocol {
    func getAvailableRooms() async throws -> [RoomResponse]
    func getMyRoom() async throws -> RoomDetailResponse?
    func getRoomDetails(roomId: Int) async throws -> RoomDetailResponse
    func createRoom(maxPlayers: Int, isPublic: Bool, ageGroup: String?) async throws -> CreateRoomResponse
    func joinRoom(roomId: Int) async throws -> JoinRoomResponse
    func joinByCode(roomCode: String) async throws -> JoinRoomResponse
    func quickMatch(maxPlayers: Int?, ageGroup: String?) async throws -> QuickMatchResponse
    func leaveRoom(roomId: Int) async throws -> LeaveRoomResponse
    func startGame(roomId: Int) async throws -> StartGameResponse
    func getRoomStats() async throws -> RoomStatsResponse
}

class RoomRepository: RoomRepositoryProtocol {
    private let networkManager = NetworkManager.shared
    
    // MARK: - Room Retrieval
    
    func getAvailableRooms() async throws -> [RoomResponse] {
        let response: [RoomResponse] = try await networkManager.get(APIConstants.Endpoints.availableRooms)
        return response
    }
    
    func getMyRoom() async throws -> RoomDetailResponse? {
        let response: RoomDetailResponse? = try await networkManager.get(APIConstants.Endpoints.myRoom)
        return response
    }
    
    func getRoomDetails(roomId: Int) async throws -> RoomDetailResponse {
        let endpoint = APIConstants.Endpoints.roomDetails.replacingOccurrences(of: "{room_id}", with: "\(roomId)")
        let response: RoomDetailResponse = try await networkManager.get(endpoint)
        return response
    }
    
    // MARK: - Room Creation
    
    func createRoom(maxPlayers: Int, isPublic: Bool, ageGroup: String?) async throws -> CreateRoomResponse {
        let request = CreateRoomRequest(max_players: maxPlayers, is_public: isPublic, age_group: ageGroup)
        let response: CreateRoomResponse = try await networkManager.post(APIConstants.Endpoints.createRoom, body: request)
        return response
    }
    
    // MARK: - Room Joining
    
    func joinRoom(roomId: Int) async throws -> JoinRoomResponse {
        let endpoint = APIConstants.Endpoints.joinRoom.replacingOccurrences(of: "{room_id}", with: "\(roomId)")
        let request = JoinRoomRequest(room_id: roomId)
        let response: JoinRoomResponse = try await networkManager.post(endpoint, body: request)
        return response
    }
    
    func joinByCode(roomCode: String) async throws -> JoinRoomResponse {
        let request = JoinByCodeRequest(room_code: roomCode)
        let response: JoinRoomResponse = try await networkManager.post(APIConstants.Endpoints.joinByCode, body: request)
        return response
    }
    
    func quickMatch(maxPlayers: Int?, ageGroup: String?) async throws -> QuickMatchResponse {
        let request = QuickMatchRequest(max_players: maxPlayers, age_group: ageGroup)
        let response: QuickMatchResponse = try await networkManager.post(APIConstants.Endpoints.quickMatch, body: request)
        return response
    }
    
    // MARK: - Room Management
    
    func leaveRoom(roomId: Int) async throws -> LeaveRoomResponse {
        let endpoint = APIConstants.Endpoints.leaveRoom.replacingOccurrences(of: "{room_id}", with: "\(roomId)")
        let request = LeaveRoomRequest(room_id: roomId)
        let response: LeaveRoomResponse = try await networkManager.post(endpoint, body: request)
        return response
    }
    
    func startGame(roomId: Int) async throws -> StartGameResponse {
        let endpoint = APIConstants.Endpoints.startGame.replacingOccurrences(of: "{room_id}", with: "\(roomId)")
        let request = StartGameRequest(room_id: roomId)
        let response: StartGameResponse = try await networkManager.post(endpoint, body: request)
        return response
    }
    
    // MARK: - Statistics
    
    func getRoomStats() async throws -> RoomStatsResponse {
        let response: RoomStatsResponse = try await networkManager.get(APIConstants.Endpoints.roomStats)
        return response
    }
}

// MARK: - Mock Repository for Testing

class MockRoomRepository: RoomRepositoryProtocol {
    var shouldSucceed = true
    var mockRooms: [RoomResponse] = []
    var mockRoomDetails: RoomDetailResponse?
    
    func getAvailableRooms() async throws -> [RoomResponse] {
        if shouldSucceed {
            return mockRooms.isEmpty ? generateMockRooms() : mockRooms
        } else {
            throw NetworkError.serverError(500)
        }
    }
    
    func getMyRoom() async throws -> RoomDetailResponse? {
        if shouldSucceed {
            return mockRoomDetails
        } else {
            throw NetworkError.serverError(500)
        }
    }
    
    func getRoomDetails(roomId: Int) async throws -> RoomDetailResponse {
        if shouldSucceed {
            return mockRoomDetails ?? generateMockRoomDetails(roomId: roomId)
        } else {
            throw NetworkError.serverError(500)
        }
    }
    
    func createRoom(maxPlayers: Int, isPublic: Bool, ageGroup: String?) async throws -> CreateRoomResponse {
        if shouldSucceed {
            let room = RoomResponse(
                id: Int.random(in: 1...1000),
                creator_id: 1,
                max_players: maxPlayers,
                status: .waiting,
                room_code: generateRoomCode(),
                is_public: isPublic,
                age_group: ageGroup,
                created_at: Date(),
                current_players: 1
            )
            
            return CreateRoomResponse(
                room: room,
                room_code: room.room_code ?? "",
                message: "Room created successfully"
            )
        } else {
            throw NetworkError.serverError(500)
        }
    }
    
    func joinRoom(roomId: Int) async throws -> JoinRoomResponse {
        if shouldSucceed {
            return JoinRoomResponse(
                room: generateMockRoomDetails(roomId: roomId),
                message: "Successfully joined room"
            )
        } else {
            throw NetworkError.serverError(500)
        }
    }
    
    func joinByCode(roomCode: String) async throws -> JoinRoomResponse {
        if shouldSucceed {
            return JoinRoomResponse(
                room: generateMockRoomDetails(roomId: 1),
                message: "Successfully joined room by code"
            )
        } else {
            throw NetworkError.serverError(500)
        }
    }
    
    func quickMatch(maxPlayers: Int?, ageGroup: String?) async throws -> QuickMatchResponse {
        if shouldSucceed {
            let room = generateMockRooms().first
            return QuickMatchResponse(
                room: room,
                message: "Found matching room",
                found_room: room != nil
            )
        } else {
            throw NetworkError.serverError(500)
        }
    }
    
    func leaveRoom(roomId: Int) async throws -> LeaveRoomResponse {
        if shouldSucceed {
            return LeaveRoomResponse(
                message: "Successfully left room",
                left_room: true
            )
        } else {
            throw NetworkError.serverError(500)
        }
    }
    
    func startGame(roomId: Int) async throws -> StartGameResponse {
        if shouldSucceed {
            return StartGameResponse(
                game_id: Int.random(in: 1...1000),
                message: "Game started successfully",
                game_started: true
            )
        } else {
            throw NetworkError.serverError(500)
        }
    }
    
    func getRoomStats() async throws -> RoomStatsResponse {
        if shouldSucceed {
            return RoomStatsResponse(
                total_rooms: 50,
                active_rooms: 10,
                total_games: 100,
                average_players_per_room: 4.5,
                popular_age_groups: [
                    AgeGroupStats(age_group: "18-25", room_count: 20, percentage: 40.0),
                    AgeGroupStats(age_group: "26-35", room_count: 15, percentage: 30.0),
                    AgeGroupStats(age_group: "36+", room_count: 15, percentage: 30.0)
                ]
            )
        } else {
            throw NetworkError.serverError(500)
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateMockRooms() -> [RoomResponse] {
        return [
            RoomResponse(
                id: 1,
                creator_id: 1,
                max_players: 6,
                status: .waiting,
                room_code: "ABC123",
                is_public: true,
                age_group: "18-25",
                created_at: Date(),
                current_players: 3
            ),
            RoomResponse(
                id: 2,
                creator_id: 2,
                max_players: 8,
                status: .playing,
                room_code: "DEF456",
                is_public: false,
                age_group: nil,
                created_at: Date().addingTimeInterval(-3600),
                current_players: 6
            ),
            RoomResponse(
                id: 3,
                creator_id: 3,
                max_players: 4,
                status: .waiting,
                room_code: "GHI789",
                is_public: true,
                age_group: "26-35",
                created_at: Date().addingTimeInterval(-1800),
                current_players: 2
            )
        ]
    }
    
    private func generateMockRoomDetails(roomId: Int) -> RoomDetailResponse {
        let room = RoomResponse(
            id: roomId,
            creator_id: 1,
            max_players: 6,
            status: .waiting,
            room_code: "ABC123",
            is_public: true,
            age_group: "18-25",
            created_at: Date(),
            current_players: 3
        )
        
        let participants = [
            RoomParticipantResponse(
                id: 1,
                room_id: roomId,
                user_id: 1,
                user_nickname: "Player1",
                joined_at: Date(),
                status: "active"
            ),
            RoomParticipantResponse(
                id: 2,
                room_id: roomId,
                user_id: 2,
                user_nickname: "Player2",
                joined_at: Date().addingTimeInterval(-300),
                status: "active"
            ),
            RoomParticipantResponse(
                id: 3,
                room_id: roomId,
                user_id: 3,
                user_nickname: "Player3",
                joined_at: Date().addingTimeInterval(-600),
                status: "ready"
            )
        ]
        
        return RoomDetailResponse(
            room: room,
            participants: participants,
            creator_nickname: "Player1",
            can_start_game: participants.count >= 2
        )
    }
    
    private func generateRoomCode() -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let numbers = "0123456789"
        let code = String((0..<3).map { _ in letters.randomElement()! }) +
                  String((0..<3).map { _ in numbers.randomElement()! })
        return code
    }
} 