import SwiftUI

struct RoomsHelpView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Заголовок
                    VStack(spacing: 8) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Как играть в комнатах?")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top)
                    
                    // Секции помощи
                    HelpSection(
                        title: "🎮 Быстрый поиск игры",
                        description: "Нажмите на желтую кнопку, чтобы быстро найти игру. Система автоматически найдет подходящую комнату или создаст новую.",
                        icon: "bolt.fill",
                        color: .yellow
                    )
                    
                    HelpSection(
                        title: "🔑 Присоединиться по коду",
                        description: "Если друг дал вам код комнаты (например, ABC123), используйте фиолетовую кнопку, чтобы присоединиться к его игре.",
                        icon: "key.fill",
                        color: .purple
                    )
                    
                    HelpSection(
                        title: "➕ Создать комнату",
                        description: "Создайте свою комнату, выберите возрастную группу и настройки. Другие игроки смогут присоединиться к вам.",
                        icon: "plus.circle.fill",
                        color: .blue
                    )
                    
                    HelpSection(
                        title: "👥 Возрастные группы",
                        description: "• Дети (6-12 лет) - простые мемы\n• Подростки (13-17 лет) - средний уровень\n• Взрослые (18+) - сложные мемы\n• Смешанная - все типы мемов",
                        icon: "person.3.fill",
                        color: .green
                    )
                    
                    HelpSection(
                        title: "🏠 Ваша комната",
                        description: "Если у вас есть активная комната, она отображается вверху. Вы можете поделиться кодом с друзьями или покинуть комнату.",
                        icon: "house.fill",
                        color: .green
                    )
                    
                    HelpSection(
                        title: "🎯 Начать игру",
                        description: "Игру можно начать только когда в комнате собралось минимум 3 игрока. Создатель комнаты может начать игру, и все игроки получат уведомление.",
                        icon: "play.fill",
                        color: .orange
                    )
                    
                    // Кнопка закрытия
                    Button("Понятно!") {
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.blue)
                    .cornerRadius(12)
                    .padding(.top, 16)
                }
                .padding()
            }
            .navigationTitle("Помощь")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }
}

struct HelpSection: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.appTextPrimary)
            }
            
            Text(description)
                .font(.body)
                .foregroundColor(.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(12)
        .glassmorphism()
    }
}

#Preview {
    RoomsHelpView()
} 