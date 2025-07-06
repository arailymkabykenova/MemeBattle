//
//  NetworkError.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case validationError(String)
    case serverError
    case httpError(statusCode: Int)
    case decodingError
    case encodingError
    case networkError(Error)
    case notConnected
    case timeout
    case websocketError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Неверный URL"
        case .invalidResponse:
            return "Неверный ответ от сервера"
        case .unauthorized:
            return "Необходима авторизация"
        case .forbidden:
            return "Доступ запрещен"
        case .notFound:
            return "Ресурс не найден"
        case .validationError(let message):
            return "Ошибка валидации: \(message)"
        case .serverError:
            return "Ошибка сервера"
        case .httpError(let statusCode):
            return "HTTP ошибка: \(statusCode)"
        case .decodingError:
            return "Ошибка декодирования ответа"
        case .encodingError:
            return "Ошибка кодирования запроса"
        case .networkError(let error):
            return "Ошибка сети: \(error.localizedDescription)"
        case .notConnected:
            return "Нет соединения с сервером"
        case .timeout:
            return "Превышено время ожидания"
        case .websocketError(let message):
            return "WebSocket ошибка: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .unauthorized:
            return "Пожалуйста, войдите в систему"
        case .networkError, .timeout, .notConnected:
            return "Проверьте подключение к интернету"
        case .serverError:
            return "Попробуйте позже"
        default:
            return "Попробуйте еще раз"
        }
    }
} 