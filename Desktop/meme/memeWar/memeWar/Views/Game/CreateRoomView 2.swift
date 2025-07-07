//
//  CreateRoomView.swift
//  memeWar
//
//  Created by Арайлым Кабыкенова on 04.07.2025.
//

import SwiftUI

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
                    Picker("Максимум игроков", selection: $maxPlayers) {
                        ForEach(3...8, id: \.self) { count in
                            Text("\(count)").tag(count)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Toggle("Публичная комната", isOn: $isPublic)
                    
                    if !isPublic {
                        Toggle("Создать код приглашения", isOn: $generateCode)
                    }
                }
                
                Section("Информация") {
                    HStack {
                        Image(systemName: "person.2.fill")
                        Text("Публичная комната")
                        Spacer()
                        Text(isPublic ? "Да" : "Нет")
                            .foregroundColor(.secondary)
                    }
                    
                    if !isPublic {
                        HStack {
                            Image(systemName: "key.fill")
                            Text("Код приглашения")
                            Spacer()
                            Text(generateCode ? "Будет создан" : "Не нужен")
                                .foregroundColor(.secondary)
                        }
                    }
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
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Создать") {
                        roomViewModel.maxPlayers = maxPlayers
                        roomViewModel.isPublic = isPublic
                        Task {
                            await roomViewModel.createRoom()
                            dismiss()
                        }
                    }
                    .disabled(roomViewModel.isLoading)
                }
            }
        }
        .onChange(of: isPublic) { newValue in
            if newValue {
                generateCode = false
            }
        }
    }
}

#Preview {
    CreateRoomView()
        .environmentObject(RoomViewModel())
} 