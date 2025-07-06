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
    @Published var showError = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Loading State
    
    func setLoading(_ loading: Bool) {
        isLoading = loading
    }
    
    // MARK: - Error Handling
    
    func setError(_ message: String?) {
        errorMessage = message
        showError = message != nil
    }
    
    func clearError() {
        errorMessage = nil
        showError = false
    }
    
    // MARK: - Async Task Helper
    
    func performAsyncTask<T>(_ task: @escaping () async throws -> T) async -> T? {
        do {
            return try await task()
        } catch {
            setError(error.localizedDescription)
            return nil
        }
    }
    
    // MARK: - Combine Helpers
    
    func addCancellable<T: Publisher>(_ publisher: T, action: @escaping (T.Output) -> Void) {
        publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: action)
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
    
    func formatPercentage(_ value: Double) -> String {
        return String(format: "%.1f%%", value * 100)
    }
    
    // MARK: - Cleanup
    
    deinit {
        cancellables.removeAll()
    }
} 