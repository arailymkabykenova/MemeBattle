//
//  RoomSheetViews.swift
//  memeWar
//
//  Created by Арайлым Кабыkенова on 04.07.2025.
//

import SwiftUI

// MARK: - Create Room View

struct CreateRoomView: View {
    @EnvironmentObject var roomViewModel: RoomViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var maxPlayers = 4
    @State private var isPublic = true
    @State private var generateCode = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Настройки комнаты") {
                    Stepper("Максимум игроков: \(maxPlayers)", value: $maxPlayers, in: 3...8)
                    
                    Toggle("Публичная комната", isOn: $isPublic)
                    
                    if !isPublic {
                        Toggle("Сгенерировать код", isOn: $generateCode)
                    }
                }
                
                Section {
                    Button("Создать комнату") {
                        Task {
                            await roomViewModel.createRoom(
                                maxPlayers: maxPlayers,
                                isPublic: isPublic,
                                generateCode: generateCode
                            )
                            dismiss()
                        }
                    }
                    .disabled(roomViewModel.isLoading)
                }
            }
            .navigationTitle("Создать комнату")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Join By Code View

struct JoinByCodeView: View {
    @EnvironmentObject var roomViewModel: RoomViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var roomCode = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppConstants.largePadding) {
                VStack(spacing: AppConstants.padding) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.accentColor)
                    
                    Text("Присоединиться к комнате")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Введите код комнаты, чтобы присоединиться к приватной игре")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: AppConstants.padding) {
                    TextField("Код комнаты", text: $roomCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textInputAutocapitalization(.characters)
                        .onChange(of: roomCode) { newValue in
                            roomCode = newValue.uppercased()
                        }
                    
                    Button("Присоединиться") {
                        roomViewModel.roomCode = roomCode
                        Task {
                            await roomViewModel.joinByCode()
                            dismiss()
                        }
                    }
                    .disabled(roomCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || roomViewModel.isLoading)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppConstants.padding)
                    .background(
                        RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                            .fill(Color.accentColor)
                    )
                    .foregroundColor(.white)
                }
                
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
        }
    }
}

// MARK: - Quick Match View

struct QuickMatchView: View {
    @EnvironmentObject var roomViewModel: RoomViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppConstants.largePadding) {
                VStack(spacing: AppConstants.padding) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("Быстрый поиск")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Найдите подходящую комнату для быстрой игры")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: AppConstants.padding) {
                    Button("Начать поиск") {
                        Task {
                            await roomViewModel.quickMatch()
                            dismiss()
                        }
                    }
                    .disabled(roomViewModel.isLoading)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppConstants.padding)
                    .background(
                        RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                            .fill(Color.green)
                    )
                    .foregroundColor(.white)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Быстрый поиск")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    JoinByCodeView()
        .environmentObject(RoomViewModel())
} 