import SwiftUI

public struct AnimatedBackgroundView: View {
    @State private var gradientOffset: CGFloat = 0
    @State private var isAnimating = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Анимированный градиент
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.8, blue: 0.7), // Персиковый
                    Color(red: 0.9, green: 0.7, blue: 1.0), // Сиреневый
                    Color(red: 0.7, green: 0.9, blue: 1.0), // Голубой
                    Color(red: 1.0, green: 0.9, blue: 0.7), // Желтый
                    Color(red: 0.9, green: 1.0, blue: 0.8)  // Мятный
                ],
                startPoint: UnitPoint(x: gradientOffset, y: 0),
                endPoint: UnitPoint(x: 1 - gradientOffset, y: 1)
            )
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeInOut(duration: Constants.Animation.backgroundShiftDuration).repeatForever(autoreverses: true)) {
                    gradientOffset = 0.3
                }
            }
            
            // Плавающие элементы
            ForEach(0..<6) { index in
                FloatingElement(index: index)
            }
        }
    }
}

public struct FloatingElement: View {
    public let index: Int
    @State private var offset = CGSize.zero
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    
    public init(index: Int) {
        self.index = index
    }
    
    private var colors: [Color] = [
        .blue.opacity(0.1),
        .purple.opacity(0.1),
        .pink.opacity(0.1),
        .orange.opacity(0.1),
        .green.opacity(0.1),
        .yellow.opacity(0.1)
    ]
    
    public var body: some View {
        Circle()
            .fill(colors[index % colors.count])
            .frame(width: CGFloat.random(in: 50...150), height: CGFloat.random(in: 50...150))
            .offset(offset)
            .rotationEffect(.degrees(rotation))
            .scaleEffect(scale)
            .onAppear {
                startFloatingAnimation()
            }
    }
    
    private func startFloatingAnimation() {
        let duration = Double.random(in: 8...15)
        let delay = Double(index) * 0.5
        
        withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true).delay(delay)) {
            offset = CGSize(
                width: CGFloat.random(in: -100...100),
                height: CGFloat.random(in: -100...100)
            )
            rotation = Double.random(in: 0...360)
            scale = CGFloat.random(in: 0.8...1.2)
        }
    }
}

#Preview {
    AnimatedBackgroundView()
} 