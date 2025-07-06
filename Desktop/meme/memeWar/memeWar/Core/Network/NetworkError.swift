//
//  NetworkError.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case encodingError
    case unauthorized
    case forbidden
    case notFound
    case serverError(Int)
    case networkError(Error)
    case notConnected
    case timeout
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Неверный URL"
        case .noData:
            return "Нет данных"
        case .decodingError:
            return "Ошибка декодирования данных"
        case .encodingError:
            return "Ошибка кодирования данных"
        case .unauthorized:
            return "Не авторизован"
        case .forbidden:
            return "Доступ запрещен"
        case .notFound:
            return "Ресурс не найден"
        case .serverError(let code):
            return "Ошибка сервера: \(code)"
        case .networkError(let error):
            return "Сетевая ошибка: \(error.localizedDescription)"
        case .notConnected:
            return "Нет соединения"
        case .timeout:
            return "Превышено время ожидания"
        case .unknown:
            return "Неизвестная ошибка"
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