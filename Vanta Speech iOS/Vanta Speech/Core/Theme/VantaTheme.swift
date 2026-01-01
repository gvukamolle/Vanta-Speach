import SwiftUI

// MARK: - Theme Environment Key

private struct VantaThemeKey: EnvironmentKey {
    static let defaultValue = VantaThemeColors.light
}

extension EnvironmentValues {
    var vantaTheme: VantaThemeColors {
        get { self[VantaThemeKey.self] }
        set { self[VantaThemeKey.self] = newValue }
    }
}

// MARK: - Theme Colors

struct VantaThemeColors {
    let background: Color
    let surface: Color
    let surfaceElevated: Color
    let textPrimary: Color
    let textSecondary: Color
    let glassTintOpacity: Double

    // Accent colors (same for both themes)
    let accentPrimary: Color = .pinkVibrant
    let accentSecondary: Color = .blueVibrant
    let glassTint: Color = .pinkLight

    static let light = VantaThemeColors(
        background: .vantaWhite,
        surface: .vantaWhite,
        surfaceElevated: .vantaWhite,
        textPrimary: .vantaCharcoal,
        textSecondary: .vantaGray,
        glassTintOpacity: 0.30
    )

    static let dark = VantaThemeColors(
        background: .darkBackground,
        surface: .darkSurface,
        surfaceElevated: .darkSurfaceElevated,
        textPrimary: .vantaWhite,
        textSecondary: .darkTextSecondary,
        glassTintOpacity: 0.15
    )
}

// MARK: - Theme View Modifier

struct VantaThemeModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .environment(\.vantaTheme, colorScheme == .dark ? .dark : .light)
    }
}

extension View {
    func vantaThemed() -> some View {
        modifier(VantaThemeModifier())
    }
}
