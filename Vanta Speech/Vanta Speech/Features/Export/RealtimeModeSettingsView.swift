import SwiftUI

struct RealtimeModeSettingsView: View {
    @AppStorage("realtime_pauseThreshold") private var pauseThreshold: Double = 3.0
    @AppStorage("vad_minChunkDuration") private var minChunkDuration: Double = 10.0
    @AppStorage("vad_maxChunkDuration") private var maxChunkDuration: Double = 60.0

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Пауза для завершения фразы")
                        Spacer()
                        Text(String(format: "%.1f сек", pauseThreshold))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $pauseThreshold, in: 1.0...5.0, step: 0.5)
                        .tint(.pinkVibrant)
                }
            } header: {
                Text("Определение пауз")
            } footer: {
                Text("Когда вы молчите дольше указанного времени, текущий фрагмент отправляется на транскрипцию. Меньшее значение = быстрее появляется текст, но может разбивать фразы.")
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
        pauseThreshold = 3.0
        minChunkDuration = 10.0
        maxChunkDuration = 60.0
    }
}

#Preview {
    NavigationStack {
        RealtimeModeSettingsView()
    }
}
