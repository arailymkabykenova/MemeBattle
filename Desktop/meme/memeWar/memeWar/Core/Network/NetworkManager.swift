//
//  NetworkManager.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import Foundation
import Combine

class NetworkManager {
    static let shared = NetworkManager()
    
    private let session: URLSession
    private let tokenManager = TokenManager.shared
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        
        session = URLSession(configuration: config)
    }
    
    // MARK: - Generic Request Methods
    
    func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Encodable? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        
        guard let url = buildURL(endpoint: endpoint, queryItems: queryItems) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authorization header if token exists
        if let token = tokenManager.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add body if provided
        if let body = body {
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                request.httpBody = try encoder.encode(body)
            } catch {
                throw NetworkError.encodingError
            }
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.unknown
            }
            
            // Handle HTTP status codes
            switch httpResponse.statusCode {
            case 200...299:
                break
            case 401:
                tokenManager.clearToken()
                throw NetworkError.unauthorized
            case 403:
                throw NetworkError.forbidden
            case 404:
                throw NetworkError.notFound
            case 500...599:
                throw NetworkError.serverError(httpResponse.statusCode)
            default:
                throw NetworkError.unknown
            }
            
            // Decode response
            do {
                let decoder = JSONDecoder()
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                decoder.dateDecodingStrategy = .formatted(formatter)
                return try decoder.decode(T.self, from: data)
            } catch {
                print("[DecodingError]", error)
                if let dataString = String(data: data, encoding: .utf8) {
                    print("[Raw JSON]", dataString)
                }
                throw NetworkError.decodingError
            }
            
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.networkError(error)
        }
    }
    
    // MARK: - Helper Methods
    
    private func buildURL(endpoint: String, queryItems: [URLQueryItem]?) -> URL? {
        var components = URLComponents(string: APIConstants.baseURL + endpoint)
        
        if let queryItems = queryItems {
            components?.queryItems = queryItems
        }
        
        return components?.url
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
        return try await request(endpoint: endpoint, method: .GET, queryItems: queryItems)
    }
    
    func post<T: Codable, U: Encodable>(_ endpoint: String, body: U) async throws -> T {
        return try await request(endpoint: endpoint, method: .POST, body: body)
    }
    
    func put<T: Codable, U: Encodable>(_ endpoint: String, body: U) async throws -> T {
        return try await request(endpoint: endpoint, method: .PUT, body: body)
    }
    
    func delete<T: Codable>(_ endpoint: String) async throws -> T {
        return try await request(endpoint: endpoint, method: .DELETE)
    }
    
    func patch<T: Codable, U: Encodable>(_ endpoint: String, body: U) async throws -> T {
        return try await request(endpoint: endpoint, method: .PATCH, body: body)
    }
} 