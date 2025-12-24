import SwiftUI

// MARK: - Sphere Style

enum SphereStyle {
    case pink, blue, gray, dark

    var gradient: [Color] {
        switch self {
        case .pink: return [Color(hex: "#F9B9EB"), Color(hex: "#FA68D5")]
        case .blue: return [Color(hex: "#B3E5FF"), Color(hex: "#3DBAFC")]
        case .gray: return [Color(hex: "#A0A0A0"), Color(hex: "#363636")]
        case .dark: return [Color(hex: "#4A4A4A"), Color(hex: "#1A1A1A")]
        }
    }
}

// MARK: - 3D Sphere View

struct VantaSphere: View {
    let style: SphereStyle
    let size: CGFloat
    var showHighlight: Bool = true

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: style.gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            if showHighlight {
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity(0.6), .clear],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: size * 0.4
                        )
                    )
                    .frame(width: size * 0.5, height: size * 0.3)
                    .offset(x: -size * 0.15, y: -size * 0.2)
            }
        }
        .shadow(color: .black.opacity(0.2), radius: size * 0.15, x: 0, y: size * 0.1)
    }
}

// MARK: - Ring / Torus View

struct VantaRing: View {
    let color: Color
    let size: CGFloat
    let lineWidth: CGFloat
    var isAnimating: Bool = false

    @State private var rotation: Double = 0

    var body: some View {
        Circle()
            .stroke(
                AngularGradient(
                    colors: [color, color.opacity(0.3), color],
                    center: .center
                ),
                lineWidth: lineWidth
            )
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                if isAnimating {
                    withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
            }
    }
}

// MARK: - Decorative Background

struct VantaDecorativeBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    private var opacity: Double {
        colorScheme == .dark ? 0.8 : 1.0
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Large pink sphere (top-right)
                VantaSphere(style: .pink, size: 180)
                    .offset(
                        x: geometry.size.width * 0.6,
                        y: -40
                    )
                    .opacity(opacity)

                // Medium blue sphere (bottom-left)
                VantaSphere(style: .blue, size: 100)
                    .offset(
                        x: -30,
                        y: geometry.size.height * 0.6
                    )
                    .opacity(opacity * 0.9)

                // Small pink sphere
                VantaSphere(style: .pink, size: 40)
                    .offset(
                        x: geometry.size.width * 0.2,
                        y: geometry.size.height * 0.3
                    )
                    .opacity(opacity * 0.85)
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Recording Indicator

struct VantaRecordingIndicator: View {
    @State private var isPulsing = false

    let size: CGFloat

    init(size: CGFloat = 80) {
        self.size = size
    }

    var body: some View {
        ZStack {
            // Outer pulse ring
            Circle()
                .stroke(Color.pinkVibrant.opacity(0.3), lineWidth: 2)
                .frame(width: size * 1.5, height: size * 1.5)
                .scaleEffect(isPulsing ? 1.2 : 1.0)
                .opacity(isPulsing ? 0 : 0.8)

            // Ring
            VantaRing(
                color: .pinkVibrant,
                size: size,
                lineWidth: 4,
                isAnimating: true
            )

            // Center sphere
            VantaSphere(style: .pink, size: size * 0.6)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }
}

#Preview("Spheres") {
    HStack(spacing: 20) {
        VantaSphere(style: .pink, size: 60)
        VantaSphere(style: .blue, size: 60)
        VantaSphere(style: .gray, size: 60)
        VantaSphere(style: .dark, size: 60)
    }
    .padding()
}

#Preview("Recording Indicator") {
    VantaRecordingIndicator()
        .padding()
}

#Preview("Decorative Background") {
    ZStack {
        Color(.systemBackground)
        VantaDecorativeBackground()
    }
    .ignoresSafeArea()
}
