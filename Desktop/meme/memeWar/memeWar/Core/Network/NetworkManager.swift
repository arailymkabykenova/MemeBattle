//
//  NetworkManager.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import Foundation

protocol NetworkManagerProtocol {
    func get<T: Codable>(endpoint: String) async throws -> T
    func post<T: Codable, U: Codable>(endpoint: String, body: U) async throws -> T
    func post<T: Codable>(endpoint: String, body: Data) async throws -> T
    func put<T: Codable, U: Codable>(endpoint: String, body: U) async throws -> T
    func delete<T: Codable>(endpoint: String) async throws -> T
}

class NetworkManager: NetworkManagerProtocol {
    static let shared = NetworkManager()
    
    private let tokenManager = TokenManager.shared
    private let session = URLSession.shared
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    private init() {
        decoder = JSONDecoder()
        encoder = JSONEncoder()
        
        // Configure date decoding
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        // Configure date encoding
        encoder.dateEncodingStrategy = .formatted(dateFormatter)
    }
    
    // MARK: - GET Request
    
    func get<T: Codable>(endpoint: String) async throws -> T {
        let url = try buildURL(endpoint: endpoint)
        let request = try buildRequest(url: url, method: "GET")
        
        let (data, response) = try await session.data(for: request)
        
        try validateResponse(response)
        return try decoder.decode(T.self, from: data)
    }
    
    // MARK: - POST Request
    
    func post<T: Codable, U: Codable>(endpoint: String, body: U) async throws -> T {
        let url = try buildURL(endpoint: endpoint)
        var request = try buildRequest(url: url, method: "POST")
        
        let bodyData = try encoder.encode(body)
        request.httpBody = bodyData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        
        try validateResponse(response)
        return try decoder.decode(T.self, from: data)
    }
    
    func post<T: Codable>(endpoint: String, body: Data) async throws -> T {
        let url = try buildURL(endpoint: endpoint)
        var request = try buildRequest(url: url, method: "POST")
        
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        
        try validateResponse(response)
        return try decoder.decode(T.self, from: data)
    }
    
    // MARK: - PUT Request
    
    func put<T: Codable, U: Codable>(endpoint: String, body: U) async throws -> T {
        let url = try buildURL(endpoint: endpoint)
        var request = try buildRequest(url: url, method: "PUT")
        
        let bodyData = try encoder.encode(body)
        request.httpBody = bodyData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        
        try validateResponse(response)
        return try decoder.decode(T.self, from: data)
    }
    
    // MARK: - DELETE Request
    
    func delete<T: Codable>(endpoint: String) async throws -> T {
        let url = try buildURL(endpoint: endpoint)
        let request = try buildRequest(url: url, method: "DELETE")
        
        let (data, response) = try await session.data(for: request)
        
        try validateResponse(response)
        return try decoder.decode(T.self, from: data)
    }
    
    // MARK: - Helper Methods
    
    private func buildURL(endpoint: String) throws -> URL {
        let baseURL = APIConstants.baseURL
        let fullURLString = baseURL + endpoint
        
        guard let url = URL(string: fullURLString) else {
            throw NetworkError.invalidURL
        }
        
        return url
    }
    
    private func buildRequest(url: URL, method: String) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = AppConstants.networkTimeout
        
        // Add authorization header if token exists
        if let token = tokenManager.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw NetworkError.unauthorized
        case 403:
            throw NetworkError.forbidden
        case 404:
            throw NetworkError.notFound
        case 422:
            throw NetworkError.validationError
        case 500...599:
            throw NetworkError.serverError
        default:
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
    }
}

// MARK: - HTTP Method Enum

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - Convenience Extensions

extension NetworkManager {
    func get<T: Codable>(_ endpoint: String, queryItems: [URLQueryItem]? = nil) async throws -> T {
        return try await get(endpoint)
    }
    
    func post<T: Codable, U: Encodable>(_ endpoint: String, body: U) async throws -> T {
        return try await post(endpoint, body: body)
    }
    
    func put<T: Codable, U: Encodable>(_ endpoint: String, body: U) async throws -> T {
        return try await put(endpoint, body: body)
    }
    
    func delete<T: Codable>(_ endpoint: String) async throws -> T {
        return try await delete(endpoint)
    }
    
    func patch<T: Codable, U: Encodable>(_ endpoint: String, body: U) async throws -> T {
        let url = try buildURL(endpoint: endpoint)
        var request = try buildRequest(url: url, method: "PATCH")
        
        let bodyData = try encoder.encode(body)
        request.httpBody = bodyData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        
        try validateResponse(response)
        return try decoder.decode(T.self, from: data)
    }
} 