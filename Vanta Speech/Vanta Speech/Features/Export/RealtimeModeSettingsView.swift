import SwiftUI

struct RealtimeModeSettingsView: View {
    @AppStorage("vad_silenceThreshold") private var silenceThreshold: Double = 0.08
    @AppStorage("vad_silenceDuration") private var silenceDuration: Double = 1.5
    @AppStorage("vad_minChunkDuration") private var minChunkDuration: Double = 10.0
    @AppStorage("vad_maxChunkDuration") private var maxChunkDuration: Double = 60.0

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Порог тишины")
                        Spacer()
                        Text(String(format: "%.0f%%", silenceThreshold * 100))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $silenceThreshold, in: 0.02...0.2, step: 0.01)
                        .tint(.pinkVibrant)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Длительность паузы")
                        Spacer()
                        Text(String(format: "%.1f сек", silenceDuration))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $silenceDuration, in: 0.5...3.0, step: 0.1)
                        .tint(.pinkVibrant)
                }
            } header: {
                Text("Определение пауз")
            } footer: {
                Text("Чанк завершается когда тишина длится дольше указанного времени. Более низкий порог = более чувствительно к тихим звукам.")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Минимальный чанк")
                        Spacer()
                        Text(String(format: "%.0f сек", minChunkDuration))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $minChunkDuration, in: 5...30, step: 1)
                        .tint(.pinkVibrant)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Максимальный чанк")
                        Spacer()
                        Text(String(format: "%.0f сек", maxChunkDuration))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $maxChunkDuration, in: 30...120, step: 5)
                        .tint(.pinkVibrant)
                }
            } header: {
                Text("Размер чанков")
            } footer: {
                Text("Более длинные чанки дают лучшую транскрипцию, но медленнее отображаются на экране.")
            }

            Section {
                Button("Сбросить по умолчанию") {
                    resetToDefaults()
                }
                .foregroundStyle(.red)
            }
        }
        .navigationTitle("Real-time настройки")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func resetToDefaults() {
        silenceThreshold = 0.08
        silenceDuration = 1.5
        minChunkDuration = 10.0
        maxChunkDuration = 60.0
    }
}

#Preview {
    NavigationStack {
        RealtimeModeSettingsView()
    }
}
