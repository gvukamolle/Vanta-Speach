import AppIntents
import Foundation
import UIKit

// MARK: - Live Activity Button Intents
// Haptic feedback работает в App Intents, так как они выполняются в контексте main app

/// Intent для паузы записи (из Live Activity)
struct PauseRecordingIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Пауза"
    static var description = IntentDescription("Ставит запись на паузу")

    @MainActor
    func perform() async throws -> some IntentResult {
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()

        let defaults = UserDefaults(suiteName: AppGroupConstants.suiteName)
        defaults?.set("pause", forKey: AppGroupConstants.recordingActionKey)
        defaults?.synchronize()

        NotificationCenter.default.post(name: .pauseRecordingFromLiveActivity, object: nil)

        return .result()
    }
}

/// Intent для возобновления записи (из Live Activity)
struct ResumeRecordingIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Продолжить"
    static var description = IntentDescription("Продолжает запись после паузы")

    @MainActor
    func perform() async throws -> some IntentResult {
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()

        let defaults = UserDefaults(suiteName: AppGroupConstants.suiteName)
        defaults?.set("resume", forKey: AppGroupConstants.recordingActionKey)
        defaults?.synchronize()

        NotificationCenter.default.post(name: .resumeRecordingFromLiveActivity, object: nil)

        return .result()
    }
}

/// Intent для остановки записи (из Live Activity)
struct StopRecordingIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Стоп"
    static var description = IntentDescription("Останавливает запись")

    @MainActor
    func perform() async throws -> some IntentResult {
        // Haptic feedback - более сильный для важного действия
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)

        let defaults = UserDefaults(suiteName: AppGroupConstants.suiteName)
        defaults?.set("stop", forKey: AppGroupConstants.recordingActionKey)
        defaults?.synchronize()

        NotificationCenter.default.post(name: .stopRecordingFromLiveActivity, object: nil)

        return .result()
    }
}

/// Intent для начала транскрипции (из Live Activity после остановки)
struct StartTranscriptionIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Сделать саммари"
    static var description = IntentDescription("Запускает транскрипцию и создание саммари")

    @MainActor
    func perform() async throws -> some IntentResult {
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()

        let defaults = UserDefaults(suiteName: AppGroupConstants.suiteName)
        defaults?.set("transcribe", forKey: AppGroupConstants.recordingActionKey)
        defaults?.synchronize()

        NotificationCenter.default.post(name: .startTranscriptionFromLiveActivity, object: nil)

        return .result()
    }
}

/// Intent для открытия записи (из Live Activity после завершения)
struct OpenRecordingIntent: AppIntent {
    static var title: LocalizedStringResource = "Открыть запись"
    static var description = IntentDescription("Открывает приложение с записью")

    static var openAppWhenRun: Bool = true

    @Parameter(title: "Recording ID")
    var recordingId: String?

    init() {}

    init(recordingId: String) {
        self.recordingId = recordingId
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        if let id = recordingId {
            NotificationCenter.default.post(
                name: .openRecordingFromLiveActivity,
                object: nil,
                userInfo: ["recordingId": id]
            )
        }
        return .result()
    }
}

/// Intent для закрытия Live Activity без транскрипции ("Отлично")
struct DismissActivityIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Отлично"
    static var description = IntentDescription("Закрывает Live Activity без транскрипции")

    @MainActor
    func perform() async throws -> some IntentResult {
        // Haptic feedback - успешное завершение
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)

        let defaults = UserDefaults(suiteName: AppGroupConstants.suiteName)
        defaults?.set("dismiss", forKey: AppGroupConstants.recordingActionKey)
        defaults?.synchronize()

        NotificationCenter.default.post(name: .dismissActivityFromLiveActivity, object: nil)

        return .result()
    }
}

/// Intent для скрытия Live Activity во время транскрипции
struct HideActivityIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Скрыть"
    static var description = IntentDescription("Скрывает Live Activity")

    @MainActor
    func perform() async throws -> some IntentResult {
        // Haptic feedback - лёгкий
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()

        let defaults = UserDefaults(suiteName: AppGroupConstants.suiteName)
        defaults?.set("hide", forKey: AppGroupConstants.recordingActionKey)
        defaults?.synchronize()

        NotificationCenter.default.post(name: .hideActivityFromLiveActivity, object: nil)

        return .result()
    }
}
