import SwiftUI
import SwiftData

@main
struct VantaSpeechApp: App {
    @StateObject private var audioRecorder = AudioRecorder()
    @StateObject private var authManager = AuthenticationManager.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Recording.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isAuthenticated {
                    ContentView()
                        .environmentObject(audioRecorder)
                } else {
                    LoginView()
                }
            }
            .tint(.pinkVibrant)
            .vantaThemed()
        }
        .modelContainer(sharedModelContainer)
    }
}
