import SwiftUI

struct ContentView: View {
    @EnvironmentObject var audioRecorder: AudioRecorder
    @State private var selectedTab: Tab = .record
    @AppStorage("appTheme") private var appTheme = AppTheme.system.rawValue

    enum Tab {
        case history
        case record
        case settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            LibraryView()
                .tabItem {
                    Label("История", systemImage: "calendar")
                }
                .tag(Tab.history)

            RecordingView()
                .tabItem {
                    Label("Запись", systemImage: "mic.fill")
                }
                .tag(Tab.record)

            SettingsView()
                .tabItem {
                    Label("Настройки", systemImage: "gear")
                }
                .tag(Tab.settings)
        }
        .tint(.pinkVibrant)
        .preferredColorScheme(colorScheme)
        .onAppear {
            configureTabBarAppearance()
        }
    }

    private func configureTabBarAppearance() {
        if #unavailable(iOS 26) {
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }

    private var colorScheme: ColorScheme? {
        switch AppTheme(rawValue: appTheme) ?? .system {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

enum AppTheme: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var displayName: String {
        switch self {
        case .system: return "Системная"
        case .light: return "Светлая"
        case .dark: return "Тёмная"
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AudioRecorder())
}
