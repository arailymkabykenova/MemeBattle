//
//  AuthRepository.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import Foundation
import Combine

protocol AuthRepositoryProtocol {
    func deviceAuth(deviceId: String) async throws -> AuthResponse
    func completeProfile(request: UserProfileCreate) async throws -> UserResponse
    func getCurrentUser() async throws -> UserResponse
    func logout() async throws
    func completeProfileRaw<T: Codable>(profile: T) async throws -> UserResponse
}

class AuthRepository: AuthRepositoryProtocol {
    private let networkManager: NetworkManagerProtocol
    private let tokenManager: TokenManagerProtocol
    
    init(networkManager: NetworkManagerProtocol = NetworkManager.shared,
         tokenManager: TokenManagerProtocol = TokenManager.shared) {
        self.networkManager = networkManager
        self.tokenManager = tokenManager
    }
    
    // MARK: - Device Authentication
    
    func deviceAuth(deviceId: String) async throws -> AuthResponse {
        let request = DeviceAuthRequest(device_id: deviceId)
        let response: AuthResponse = try await networkManager.post(
            endpoint: APIConstants.Endpoints.deviceAuth,
            body: request
        )
        
        // Save token
        tokenManager.saveToken(response.access_token)
        
        return response
    }
    
    // MARK: - Profile Management
    
    func completeProfile(request: UserProfileCreate) async throws -> UserResponse {
        let response: UserResponse = try await networkManager.post(
            endpoint: APIConstants.Endpoints.completeProfile,
            body: request
        )
        
        return response
    }
    
    func getCurrentUser() async throws -> UserResponse {
        let response: UserResponse = try await networkManager.get(
            endpoint: APIConstants.Endpoints.me
        )
        
        return response
    }
    
    func completeProfileRaw<T: Codable>(profile: T) async throws -> UserResponse {
        // Convert the generic Codable type to Data first, then post
        let data = try JSONEncoder().encode(profile)
        let response: UserResponse = try await networkManager.post(
            endpoint: APIConstants.Endpoints.completeProfile,
            body: data
        )
        return response
    }
    
    // MARK: - Logout
    
    func logout() async throws {
        try await networkManager.post(
            endpoint: APIConstants.Endpoints.logout,
            body: EmptyRequest()
        )
        
        // Clear token
        tokenManager.clearToken()
    }
}

// MARK: - Helper Models

private struct EmptyRequest: Codable {}

// MARK: - Mock Repository for Testing

class MockAuthRepository: AuthRepositoryProtocol {
    var shouldSucceed = true
    var mockUser: UserResponse?
    var mockAuthResponse: AuthResponse?
    
    func deviceAuth(deviceId: String) async throws -> AuthResponse {
        if shouldSucceed {
            return mockAuthResponse ?? AuthResponse(
                access_token: "mock_token",
                token_type: "Bearer",
                user: mockUser ?? UserResponse(
                    id: 1,
                    device_id: deviceId,
                    nickname: "TestUser",
                    birth_date: Date(),
                    gender: .male,
                    created_at: Date(),
                    age: 25,
                    is_profile_complete: true
                ),
                is_new_user: true
            )
        } else {
            throw NetworkError.unauthorized
        }
    }
    
    func completeProfile(request: UserProfileCreate) async throws -> UserResponse {
        if shouldSucceed {
            return mockUser ?? UserResponse(
                id: 1,
                device_id: "mock_device",
                nickname: request.nickname,
                birth_date: request.birth_date,
                gender: request.gender,
                created_at: Date(),
                age: Calendar.current.dateComponents([.year], from: request.birth_date, to: Date()).year,
                is_profile_complete: true
            )
        } else {
            throw NetworkError.serverError
        }
    }
    
    func getCurrentUser() async throws -> UserResponse {
        if shouldSucceed {
            return mockUser ?? UserResponse(
                id: 1,
                device_id: "mock_device",
                nickname: "TestUser",
                birth_date: Date(),
                gender: .male,
                created_at: Date(),
                age: 25,
                is_profile_complete: true
            )
        } else {
            throw NetworkError.unauthorized
        }
    }
    
    func logout() async throws {
        if shouldSucceed {
            // Mock logout success
        } else {
            throw NetworkError.serverError
        }
    }
    
    func completeProfileRaw<T: Codable>(profile: T) async throws -> UserResponse {
        if shouldSucceed {
            return mockUser ?? UserResponse(
                id: 1,
                device_id: "mock_device",
                nickname: "TestUser",
                birth_date: Date(),
                gender: .male,
                created_at: Date(),
                age: 25,
                is_profile_complete: true
            )
        } else {
            throw NetworkError.serverError
        }
    }
} 