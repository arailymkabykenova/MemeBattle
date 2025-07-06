//
//  JoinRoomView.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import SwiftUI

struct JoinRoomView: View {
    @EnvironmentObject var roomViewModel: RoomViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var roomCode = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppConstants.largePadding) {
                // Header
                VStack(spacing: AppConstants.padding) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.accentColor)
                    
                    Text("Присоединиться к комнате")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Введите код приглашения от друга")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Code Input
                VStack(spacing: AppConstants.padding) {
                    TextField("Код комнаты", text: $roomCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title2)
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.characters)
                        .onChange(of: roomCode) { newValue in
                            roomCode = newValue.uppercased()
                        }
                    
                    Text("Пример: ABC123")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, AppConstants.largePadding)
                
                Spacer()
                
                // Join Button
                Button(action: {
                    Task {
                        await joinRoom()
                    }
                }) {
                    HStack {
                        if roomViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "person.2.fill")
                        }
                        
                        Text(roomViewModel.isLoading ? "Присоединение..." : "Присоединиться")
                            .fontWeight(.medium)
                    }
                    .font(.body)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppConstants.padding)
                    .background(
                        RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                            .fill(isFormValid ? Color.accentColor : Color.gray)
                    )
                }
                .disabled(!isFormValid || roomViewModel.isLoading)
                .padding(.horizontal, AppConstants.largePadding)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Присоединиться")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
            .alert("Ошибка", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        roomCode.count >= 3 && roomCode.count <= 10
    }
    
    private func joinRoom() async {
        await roomViewModel.joinRoomByCode(code: roomCode)
        
        if roomViewModel.showError {
            errorMessage = roomViewModel.errorMessage ?? "Не удалось присоединиться к комнате"
            showingError = true
        } else {
            dismiss()
        }
    }
}

#Preview {
    JoinRoomView()
        .environmentObject(RoomViewModel())
} 