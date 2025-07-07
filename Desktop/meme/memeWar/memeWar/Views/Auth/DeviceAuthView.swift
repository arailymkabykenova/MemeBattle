//
//  DeviceAuthView.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import SwiftUI

struct DeviceAuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var deviceId = ""
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Meme War")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Карточная игра с мемами")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(spacing: 20) {
                Button(action: {
                    Task {
                        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
                        await authViewModel.deviceAuth(deviceId: deviceId)
                    }
                }) {
                    HStack {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "play.fill")
                        }
                        Text("Начать игру")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(authViewModel.isLoading)
                
                Text("Автоматическая авторизация по устройству")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    DeviceAuthView()
        .environmentObject(AuthViewModel())
} 