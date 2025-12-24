import SwiftUI

// MARK: - Primary Button Style

struct VantaPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(isEnabled ? Color.pinkVibrant : Color.vantaGray)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style (Glass)

struct VantaSecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .foregroundStyle(colorScheme == .dark ? .white : Color.vantaCharcoal)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background {
                if #available(iOS 26, *) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.clear)
                        .glassEffect()
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.pinkLight, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Icon Button Style (Circular)

struct VantaIconButtonStyle: ButtonStyle {
    let size: CGFloat
    let isPrimary: Bool

    init(size: CGFloat = 64, isPrimary: Bool = true) {
        self.size = size
        self.isPrimary = isPrimary
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2)
            .foregroundStyle(isPrimary ? .white : .primary)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(isPrimary ? Color.pinkVibrant : Color(.systemGray5))
            )
            .shadow(
                color: isPrimary ? Color.pinkVibrant.opacity(0.3) : .black.opacity(0.1),
                radius: 6,
                y: 3
            )
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Glass Icon Button Style

struct VantaGlassIconButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme

    let size: CGFloat

    init(size: CGFloat = 48) {
        self.size = size
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3)
            .foregroundStyle(colorScheme == .dark ? .white : Color.vantaCharcoal)
            .frame(width: size, height: size)
            .background {
                if #available(iOS 26, *) {
                    Circle()
                        .fill(.clear)
                        .glassEffect()
                } else {
                    Circle()
                        .fill(.ultraThinMaterial)
                }
            }
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Extension Shortcuts

extension ButtonStyle where Self == VantaPrimaryButtonStyle {
    static var vantaPrimary: VantaPrimaryButtonStyle { VantaPrimaryButtonStyle() }
}

extension ButtonStyle where Self == VantaSecondaryButtonStyle {
    static var vantaSecondary: VantaSecondaryButtonStyle { VantaSecondaryButtonStyle() }
}
