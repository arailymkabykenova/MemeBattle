//
//  AuthModels.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import Foundation

// MARK: - Auth Response

struct AuthResponse: Codable {
    let access_token: String
    let token_type: String
    let user: UserResponse
    let is_new_user: Bool
}

// MARK: - Device Auth Request

struct DeviceAuthRequest: Codable {
    let device_id: String
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