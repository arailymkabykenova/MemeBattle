import SwiftUI

// MARK: - Color Extensions
extension Color {
    // Primary Colors
    static let primaryColor = Color("PrimaryColor")
    static let secondaryColor = Color("SecondaryColor")
    static let backgroundColor = Color("BackgroundColor")
    static let cardBackground = Color("CardBackground")
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    
    // Accent Colors
    static let accentBlue = Color(red: 0.4, green: 0.7, blue: 1.0)
    static let accentPurple = Color(red: 0.7, green: 0.4, blue: 1.0)
    static let accentPink = Color(red: 1.0, green: 0.4, blue: 0.7)
    static let accentOrange = Color(red: 1.0, green: 0.7, blue: 0.4)
    static let accentGreen = Color(red: 0.4, green: 1.0, blue: 0.7)
    
    // Rarity Colors
    static let commonColor = Color.gray
    static let rareColor = Color.blue
    static let epicColor = Color.purple
    static let legendaryColor = Color.orange
    
    // Status Colors
    static let successColor = Color.green
    static let warningColor = Color.yellow
    static let errorColor = Color.red
    static let infoColor = Color.blue
}

// MARK: - Linear Gradient Extensions
extension LinearGradient {
    // Animated Background Gradient
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
    
    // Card Gradients
    static let cardGradient = LinearGradient(
        colors: [.cardBackground, .cardBackground.opacity(0.8)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // Button Gradients
    static let primaryButtonGradient = LinearGradient(
        colors: [.primaryColor, .primaryColor.opacity(0.8)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let secondaryButtonGradient = LinearGradient(
        colors: [.secondaryColor, .secondaryColor.opacity(0.8)],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Transition Extensions
extension AnyTransition {
    // Juicy Appear Transition
    static let juicyAppear = AnyTransition.scale(scale: 0.8)
        .combined(with: .opacity)
        .animation(.spring(response: 0.6, dampingFraction: 0.8))
    
    // Slide Up Transition
    static let slideUp = AnyTransition.move(edge: .bottom)
        .combined(with: .opacity)
        .animation(.spring(response: 0.6, dampingFraction: 0.8))
    
    // Slide Down Transition
    static let slideDown = AnyTransition.move(edge: .top)
        .combined(with: .opacity)
        .animation(.spring(response: 0.6, dampingFraction: 0.8))
    
    // Card Flip Transition
    static let cardFlip = AnyTransition.asymmetric(
        insertion: .scale(scale: 0.8).combined(with: .opacity),
        removal: .scale(scale: 1.2).combined(with: .opacity)
    ).animation(.spring(response: 0.6, dampingFraction: 0.8))
}

// MARK: - Animation Extensions
extension Animation {
    // Juicy Animations
    static let juicySpring = Animation.spring(response: 0.6, dampingFraction: 0.8)
    static let juicyBounce = Animation.spring(response: 0.5, dampingFraction: 0.6)
    static let juicyEase = Animation.easeInOut(duration: 0.3)
    
    // Card Animations
    static let cardDeal = Animation.spring(response: 0.8, dampingFraction: 0.7)
    static let cardFlip = Animation.spring(response: 0.6, dampingFraction: 0.8)
    static let cardHover = Animation.easeInOut(duration: 0.2)
}

// MARK: - View Extensions
extension View {
    // Glassmorphism Effect
    func glassmorphism() -> some View {
        self
            .background(.ultraThinMaterial)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    // Neon Glow Effect
    func neonGlow(color: Color = .blue, radius: CGFloat = 5) -> some View {
        self
            .shadow(color: color, radius: radius)
            .shadow(color: color.opacity(0.5), radius: radius * 2)
    }
    
    // Card Style
    func cardStyle() -> some View {
        self
            .background(LinearGradient.cardGradient)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // Primary Button Style
    func primaryButtonStyle() -> some View {
        self
            .background(LinearGradient.primaryButtonGradient)
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: .primaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    // Secondary Button Style
    func secondaryButtonStyle() -> some View {
        self
            .background(LinearGradient.secondaryButtonGradient)
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: .secondaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    // Haptic Feedback
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        self.onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred()
        }
    }
    
    // Success Haptic
    func successHaptic() -> some View {
        self.onTapGesture {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
    
    // Error Haptic
    func errorHaptic() -> some View {
        self.onTapGesture {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
}

// MARK: - Image Extensions
extension Image {
    // SF Symbol with Gradient
    func sfSymbolGradient(_ colors: [Color]) -> some View {
        self
            .foregroundStyle(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
    }
    
    // SF Symbol with Rarity Color
    func sfSymbolRarity(_ rarity: CardRarity) -> some View {
        self.foregroundColor(rarityColor(for: rarity))
    }
    
    private func rarityColor(for rarity: CardRarity) -> Color {
        switch rarity {
        case .common: return .commonColor
        case .rare: return .rareColor
        case .epic: return .epicColor
        case .legendary: return .legendaryColor
        }
    }
}

// MARK: - Text Extensions
extension Text {
    // Title Style
    func titleStyle() -> some View {
        self
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.textPrimary)
    }
    
    // Subtitle Style
    func subtitleStyle() -> some View {
        self
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(.textPrimary)
    }
    
    // Body Style
    func bodyStyle() -> some View {
        self
            .font(.body)
            .foregroundColor(.textPrimary)
    }
    
    // Caption Style
    func captionStyle() -> some View {
        self
            .font(.caption)
            .foregroundColor(.textSecondary)
    }
    
    // Rarity Style
    func rarityStyle(_ rarity: CardRarity) -> some View {
        self
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(rarityColor(for: rarity))
    }
    
    private func rarityColor(for rarity: CardRarity) -> Color {
        switch rarity {
        case .common: return .commonColor
        case .rare: return .rareColor
        case .epic: return .epicColor
        case .legendary: return .legendaryColor
        }
    }
} 