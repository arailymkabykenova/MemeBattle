//
//  AuthModels.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import Foundation

// MARK: - Authentication Models

struct AuthResponse: Codable {
    let access_token: String
    let token_type: String
    let user: UserResponse
    let is_new_user: Bool
}

struct DeviceAuthRequest: Codable {
    let device_id: String
}

struct UserProfileCreate: Codable {
    let nickname: String
    let birth_date: Date
    let gender: Gender
}

struct LogoutResponse: Codable {
    let message: String
}

// MARK: - Error Response Models

struct ErrorResponse: Codable {
    let detail: String
    let error_code: String?
    let field_errors: [FieldError]?
}

struct FieldError: Codable {
    let field: String
    let message: String
}

// MARK: - Success Response Models

struct SuccessResponse: Codable {
    let message: String
    let success: Bool
} 