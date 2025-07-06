//
//  BaseViewModel.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import Foundation
import Combine

@MainActor
class BaseViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Error Handling
    
    func handleError(_ error: Error) {
        if let networkError = error as? NetworkError {
            errorMessage = networkError.errorDescription
        } else {
            errorMessage = error.localizedDescription
        }
        showError = true
        isLoading = false
    }
    
    func clearError() {
        errorMessage = nil
        showError = false
    }
    
    // MARK: - Loading State
    
    func setLoading(_ loading: Bool) {
        isLoading = loading
        if loading {
            clearError()
        }
    }
    
    // MARK: - Async Task Wrapper
    
    func performAsyncTask<T>(_ task: @escaping () async throws -> T) async -> T? {
        setLoading(true)
        
        do {
            let result = try await task()
            setLoading(false)
            return result
        } catch {
            handleError(error)
            return nil
        }
    }
    
    // MARK: - Combine Helpers
    
    func addCancellable<T>(_ publisher: AnyPublisher<T, Never>, receiveValue: @escaping (T) -> Void) {
        publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: receiveValue)
            .store(in: &cancellables)
    }
    
    // MARK: - Validation
    
    func validateNickname(_ nickname: String) -> Bool {
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 3 && trimmed.count <= 20
    }
    
    func validateAge(_ birthDate: Date) -> Bool {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        let age = ageComponents.year ?? 0
        return age >= 13 && age <= 100
    }
    
    // MARK: - Formatting
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
    }
    
    func formatRating(_ rating: Double) -> String {
        return String(format: "%.1f", rating)
    }
    
    func formatPercentage(_ value: Double) -> String {
        return String(format: "%.1f%%", value * 100)
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        cancellables.removeAll()
    }
    
    deinit {
        Task { @MainActor in
            cleanup()
        }
    }
} 