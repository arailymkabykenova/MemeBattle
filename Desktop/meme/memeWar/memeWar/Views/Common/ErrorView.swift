//
//  ErrorView.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import SwiftUI

struct ErrorView: View {
    let error: String
    let retryAction: (() -> Void)?
    
    init(_ error: String, retryAction: (() -> Void)? = nil) {
        self.error = error
        self.retryAction = retryAction
    }
    
    var body: some View {
        VStack(spacing: AppConstants.largePadding) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Произошла ошибка")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text(error)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppConstants.largePadding)
            
            if let retryAction = retryAction {
                Button(action: retryAction) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Повторить")
                            .fontWeight(.medium)
                    }
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, AppConstants.largePadding)
                    .padding(.vertical, AppConstants.padding)
                    .background(
                        RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                            .fill(Color.accentColor)
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct ErrorAlert: ViewModifier {
    let error: String?
    let isPresented: Binding<Bool>
    let retryAction: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .alert("Ошибка", isPresented: isPresented) {
                Button("OK") {
                    isPresented.wrappedValue = false
                }
                
                if let retryAction = retryAction {
                    Button("Повторить") {
                        retryAction()
                        isPresented.wrappedValue = false
                    }
                }
            } message: {
                Text(error ?? "Произошла неизвестная ошибка")
            }
    }
}

struct ErrorBanner: View {
    let error: String
    let dismissAction: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.circle")
                .foregroundColor(.red)
            
            Text(error)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            Spacer()
            
            Button(action: dismissAction) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding(AppConstants.smallPadding)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, AppConstants.padding)
    }
}

// MARK: - View Extensions

extension View {
    func errorAlert(error: String?, isPresented: Binding<Bool>, retryAction: (() -> Void)? = nil) -> some View {
        modifier(ErrorAlert(error: error, isPresented: isPresented, retryAction: retryAction))
    }
}

#Preview {
    ErrorView("Не удалось загрузить данные") {
        print("Retry tapped")
    }
} 