import SwiftUI

// MARK: - Animation Timing

enum VantaAnimation {
    static let fast: Double = 0.15
    static let normal: Double = 0.25
    static let slow: Double = 0.40

    // Spring presets
    static var bouncy: Animation {
        .spring(response: 0.5, dampingFraction: 0.7)
    }

    static var smooth: Animation {
        .easeOut(duration: normal)
    }

    static var snappy: Animation {
        .easeInOut(duration: fast)
    }

    static var glassAppear: Animation {
        .easeOut(duration: normal).delay(0.05)
    }
}

// MARK: - Transitions

extension AnyTransition {
    static var vantaScale: AnyTransition {
        .scale(scale: 0.95)
            .combined(with: .opacity)
    }

    static var vantaSlide: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
}

// MARK: - Pulse Animation Modifier

struct VantaPulseModifier: ViewModifier {
    @State private var isPulsing = false

    let color: Color
    let duration: Double

    init(color: Color = .pinkVibrant, duration: Double = 0.8) {
        self.color = color
        self.duration = duration
    }

    func body(content: Content) -> some View {
        content
            .overlay(
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: 2)
                    .scaleEffect(isPulsing ? 1.5 : 1.0)
                    .opacity(isPulsing ? 0 : 0.8)
            )
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: false)) {
                    isPulsing = true
                }
            }
    }
}

extension View {
    func vantaPulse(color: Color = .pinkVibrant, duration: Double = 0.8) -> some View {
        modifier(VantaPulseModifier(color: color, duration: duration))
    }
}
