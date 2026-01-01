import AppIntents
import Foundation
import UIKit

/// Intent для начала записи через Shortcuts
struct StartRecordingIntent: AppIntent {

    static var title: LocalizedStringResource = "Начать запись"
    static var description = IntentDescription("Начинает запись встречи с выбранным шаблоном в Vanta Speech")

    // Открываем приложение для записи - необходимо для запуска AudioSession
    // iOS не позволяет начать запись без активного приложения
    static var openAppWhenRun: Bool = true

    // MARK: - Parameters

    @Parameter(
        title: "Шаблон",
        description: "Тип встречи для правильного саммари"
    )
    var preset: PresetEntity

    // MARK: - Parameter Summary

    static var parameterSummary: some ParameterSummary {
        Summary("Начать запись \(\.$preset)")
    }

    // MARK: - Perform

    @MainActor
    func perform() async throws -> some IntentResult {
        // Хаптик при запуске записи
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Сохраняем выбранный preset и timestamp в App Group
        let defaults = UserDefaults(suiteName: AppGroupConstants.suiteName)
        defaults?.set(preset.id, forKey: "pending_recording_preset")
        defaults?.set(Date().timeIntervalSince1970, forKey: "pending_recording_timestamp")
        defaults?.synchronize()

        // Отправляем notification в основное приложение
        NotificationCenter.default.post(
            name: .startRecordingFromShortcut,
            object: nil,
            userInfo: ["presetId": preset.id]
        )

        return .result()
    }
}

// MARK: - Stop Recording Intent (для Shortcuts)

/// Intent для остановки записи через Shortcuts
struct StopRecordingShortcutIntent: AppIntent {

    static var title: LocalizedStringResource = "Остановить запись"
    static var description = IntentDescription("Останавливает текущую запись в Vanta Speech")

    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: AppGroupConstants.suiteName)
        defaults?.set("stop", forKey: AppGroupConstants.recordingActionKey)
        defaults?.synchronize()

        NotificationCenter.default.post(name: .stopRecordingFromLiveActivity, object: nil)

        return .result()
    }
}
