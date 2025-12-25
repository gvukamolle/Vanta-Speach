import Foundation
import SwiftUI
import Combine

/// Manages preset order and enabled/disabled state
@MainActor
final class PresetSettings: ObservableObject {
    static let shared = PresetSettings()

    private let defaults: UserDefaults
    private let orderKey = AppGroupConstants.presetOrderKey
    private let disabledKey = AppGroupConstants.disabledPresetsKey

    private init() {
        // Use App Group UserDefaults for sharing with Widget Extension
        self.defaults = UserDefaults(suiteName: AppGroupConstants.suiteName) ?? .standard
        loadSettings()
    }

    @Published private(set) var orderedPresets: [RecordingPreset] = []
    @Published private(set) var disabledPresets: Set<RecordingPreset> = []

    // MARK: - Public API

    /// Get only enabled presets in user-defined order
    var enabledPresets: [RecordingPreset] {
        orderedPresets.filter { !disabledPresets.contains($0) }
    }

    /// Check if a preset is enabled
    func isEnabled(_ preset: RecordingPreset) -> Bool {
        !disabledPresets.contains(preset)
    }

    /// Toggle preset enabled state
    func togglePreset(_ preset: RecordingPreset) {
        if disabledPresets.contains(preset) {
            disabledPresets.remove(preset)
        } else {
            // Don't allow disabling if it would leave no presets
            let enabledCount = orderedPresets.filter { !disabledPresets.contains($0) }.count
            if enabledCount > 1 {
                disabledPresets.insert(preset)
            }
        }
        saveDisabled()
    }

    /// Set preset enabled state
    func setEnabled(_ preset: RecordingPreset, enabled: Bool) {
        if enabled {
            disabledPresets.remove(preset)
        } else {
            let enabledCount = orderedPresets.filter { !disabledPresets.contains($0) }.count
            if enabledCount > 1 {
                disabledPresets.insert(preset)
            }
        }
        saveDisabled()
    }

    /// Move preset in the order
    func movePreset(from source: IndexSet, to destination: Int) {
        orderedPresets.move(fromOffsets: source, toOffset: destination)
        saveOrder()
    }

    /// Reset to default order and all enabled
    func resetToDefaults() {
        orderedPresets = Array(RecordingPreset.allCases)
        disabledPresets = []
        saveOrder()
        saveDisabled()
    }

    // MARK: - Persistence

    private func loadSettings() {
        // Load order
        if let rawValues = defaults.stringArray(forKey: orderKey) {
            let presets = rawValues.compactMap { RecordingPreset(rawValue: $0) }
            // Add any missing presets at the end
            var result = presets
            for preset in RecordingPreset.allCases where !result.contains(preset) {
                result.append(preset)
            }
            orderedPresets = result
        } else {
            orderedPresets = Array(RecordingPreset.allCases)
        }

        // Load disabled
        if let rawValues = defaults.stringArray(forKey: disabledKey) {
            disabledPresets = Set(rawValues.compactMap { RecordingPreset(rawValue: $0) })
        } else {
            disabledPresets = []
        }
    }

    private func saveOrder() {
        let rawValues = orderedPresets.map { $0.rawValue }
        defaults.set(rawValues, forKey: orderKey)
    }

    private func saveDisabled() {
        let rawValues = Array(disabledPresets).map { $0.rawValue }
        defaults.set(rawValues, forKey: disabledKey)
    }
}
