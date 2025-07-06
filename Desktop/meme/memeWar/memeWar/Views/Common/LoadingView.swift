//
//  LoadingView.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import SwiftUI

struct LoadingView: View {
    let message: String
    
    init(_ message: String = "Загрузка...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: AppConstants.largePadding) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                .scaleEffect(1.5)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct LoadingOverlay: View {
    let message: String
    
    init(_ message: String = "Загрузка...") {
        self.message = message
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: AppConstants.smallPadding) {
                ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Text(message)
                    .font(.caption)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .padding(AppConstants.padding)
            .background(
                RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                    .fill(Color(.systemGray6))
                    .shadow(radius: 10)
            )
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        LoadingView("Загружаем данные...")
        
        ZStack {
            Color.blue
            LoadingOverlay("Обрабатываем...")
        }
        .frame(height: 200)
    }
} 