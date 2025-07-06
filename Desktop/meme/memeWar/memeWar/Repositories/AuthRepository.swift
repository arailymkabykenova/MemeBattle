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
    func completeProfile(profile: UserProfileCreate) async throws -> UserResponse
    func getCurrentUser() async throws -> UserResponse
    func logout() async throws -> LogoutResponse
}

class AuthRepository: AuthRepositoryProtocol {
    private let networkManager = NetworkManager.shared
    private let tokenManager = TokenManager.shared
    
    // MARK: - Device Authentication
    
    func deviceAuth(deviceId: String) async throws -> AuthResponse {
        let request = DeviceAuthRequest(device_id: deviceId)
        let response: AuthResponse = try await networkManager.post(APIConstants.Endpoints.deviceAuth, body: request)
        
        // Save token after successful authentication
        tokenManager.saveToken(response.access_token)
        
        return response
    }
    
    // MARK: - Profile Management
    
    func completeProfile(profile: UserProfileCreate) async throws -> UserResponse {
        let response: UserResponse = try await networkManager.post(APIConstants.Endpoints.completeProfile, body: profile)
        return response
    }
    
    func getCurrentUser() async throws -> UserResponse {
        let response: UserResponse = try await networkManager.get(APIConstants.Endpoints.me)
        return response
    }
    
    // MARK: - Logout
    
    func logout() async throws -> LogoutResponse {
        let response: LogoutResponse = try await networkManager.post(APIConstants.Endpoints.logout, body: EmptyRequest())
        
        // Clear token after successful logout
        tokenManager.clearToken()
        
        return response
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
                    rating: 1000.0,
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
    
    func completeProfile(profile: UserProfileCreate) async throws -> UserResponse {
        if shouldSucceed {
            return mockUser ?? UserResponse(
                id: 1,
                device_id: "mock_device",
                nickname: profile.nickname,
                birth_date: profile.birth_date,
                gender: profile.gender,
                rating: 1000.0,
                created_at: Date(),
                age: Calendar.current.dateComponents([.year], from: profile.birth_date, to: Date()).year,
                is_profile_complete: true
            )
        } else {
            throw NetworkError.serverError(500)
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
                rating: 1000.0,
                created_at: Date(),
                age: 25,
                is_profile_complete: true
            )
        } else {
            throw NetworkError.unauthorized
        }
    }
    
    func logout() async throws -> LogoutResponse {
        if shouldSucceed {
            return LogoutResponse(message: "Successfully logged out")
        } else {
            throw NetworkError.serverError(500)
        }
    }
} 