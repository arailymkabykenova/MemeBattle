import SwiftUI
import Foundation
import os

// MARK: - LinearGradient Extensions
extension LinearGradient {
    // Анимированный градиент из пастельных цветов
    static let animatedBackground = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.8, blue: 0.7), // Персиковый
            Color(red: 0.9, green: 0.7, blue: 1.0), // Сиреневый
            Color(red: 0.7, green: 0.9, blue: 1.0), // Голубой
            Color(red: 1.0, green: 0.9, blue: 0.7), // Желтый
            Color(red: 0.9, green: 1.0, blue: 0.8)  // Мятный
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Акцентный градиент
    static let accentGradient = LinearGradient(
        colors: [.blue, .purple],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - Color Extensions
extension Color {
    static let appPrimaryColor = Color("PrimaryColor")
    static let appSecondaryColor = Color("SecondaryColor")
    static let appBackgroundColor = Color("BackgroundColor")
    static let appCardBackground = Color("CardBackground")
    static let appTextPrimary = Color("TextPrimary")
    static let appTextSecondary = Color("TextSecondary")
    
    // Анимированный градиент из пастельных цветов (для обратной совместимости)
    static let animatedBackground = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.8, blue: 0.7), // Персиковый
            Color(red: 0.9, green: 0.7, blue: 1.0), // Сиреневый
            Color(red: 0.7, green: 0.9, blue: 1.0), // Голубой
            Color(red: 1.0, green: 0.9, blue: 0.7), // Желтый
            Color(red: 0.9, green: 1.0, blue: 0.8)  // Мятный
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Дополнительные цвета для анимаций
    static let accentGradient = LinearGradient(
        colors: [.blue, .purple],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Image Extensions
extension Image {
    func neonGlow(color: Color = .blue, radius: CGFloat = 5) -> some View {
        self
            .shadow(color: color, radius: radius)
            .shadow(color: color.opacity(0.5), radius: radius * 2)
    }
    
    func cardStyle() -> some View {
        self
            .resizable()
            .aspectRatio(Constants.UI.cardAspectRatio, contentMode: .fit)
            .background(Color.appCardBackground)
            .cornerRadius(Constants.UI.cornerRadius)
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

// MARK: - View Extensions
extension View {
    func glassmorphism() -> some View {
        self
            .background(.ultraThinMaterial)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    func juicyAppear() -> some View {
        self
            .transition(.scale(scale: 0.8).combined(with: .opacity))
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: true)
    }
    
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) -> some View {
        self.onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred()
        }
    }
    
    func successHaptic() -> some View {
        self
            .onTapGesture {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
    }
    
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - AnyTransition Extensions
extension AnyTransition {
    static let juicyAppear = AnyTransition.scale(scale: 0.8)
        .combined(with: .opacity)
        .animation(.spring(response: 0.6, dampingFraction: 0.8))
    
    static let cardDeal = AnyTransition.move(edge: .bottom)
        .combined(with: .scale(scale: 0.5))
        .animation(.spring(response: 0.8, dampingFraction: 0.7))
    
    static let cardFlip = AnyTransition.asymmetric(
        insertion: .scale(scale: 0.8).combined(with: .opacity),
        removal: .scale(scale: 1.2).combined(with: .opacity)
    )
}

// MARK: - Animation Extensions
extension Animation {
    static let juicySpring = Animation.spring(response: 0.6, dampingFraction: 0.8)
    static let cardSpring = Animation.spring(response: 0.8, dampingFraction: 0.7)
    static let backgroundShift = Animation.easeInOut(duration: Constants.Animation.backgroundShiftDuration)
}

extension Notification.Name {
    static let userDidAuthenticate = Notification.Name("userDidAuthenticate")
}

// MARK: - String Extensions
extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
}

// MARK: - Date Extensions
extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    var yyyyMMdd: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
}

// MARK: - Custom Shapes
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - RoundedRectangle Extensions
extension RoundedRectangle {
    init(cornerRadius: CGFloat, corners: UIRectCorner) {
        self.init(cornerRadius: cornerRadius, style: .continuous)
        self.corners = corners
    }
    
    var corners: UIRectCorner {
        get { UIRectCorner() }
        set { }
    }
}

// MARK: - Room Extensions
// canJoin, roomStatus, ageGroup уже определены в Room.swift

// MARK: - AgeGroup Extensions
// displayName уже определен в User.swift

// MARK: - RoomStatus Extensions
// RoomStatus уже определен в Room.swift

// MARK: - Constants
// Constants уже определен в Constants.swift

// MARK: - UIImpactFeedbackGenerator Extensions
extension UIImpactFeedbackGenerator {
    static func playSelection() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    static func playSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
} 