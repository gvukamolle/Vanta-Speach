import SwiftUI

struct ActiveRecordingSheet: View {
    @EnvironmentObject var recorder: AudioRecorder
    @Environment(\.dismiss) private var dismiss
    let preset: RecordingPreset
    let onStop: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Drag indicator
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            // Preset indicator
            HStack(spacing: 8) {
                Image(systemName: preset.icon)
                Text(preset.displayName)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Spacer()

            // Timer with milliseconds
            Text(formatTimeWithMilliseconds(recorder.recordingDuration))
                .font(.system(size: 44, weight: .light, design: .monospaced))
                .foregroundStyle(recorder.isInterrupted ? .orange : .primary)
                .contentTransition(.numericText())
                .animation(.linear(duration: 0.05), value: recorder.recordingDuration)

            // Status indicator
            HStack(spacing: 8) {
                if recorder.isRecording && !recorder.isInterrupted {
                    Circle()
                        .fill(Color.pinkVibrant)
                        .frame(width: 8, height: 8)
                        .modifier(PulseAnimation())

                    Text("Запись")
                        .foregroundStyle(Color.pinkVibrant)
                } else if recorder.isInterrupted {
                    Image(systemName: "pause.circle.fill")
                        .foregroundStyle(Color.blueVibrant)

                    Text("Пауза")
                        .foregroundStyle(Color.blueVibrant)
                }
            }
            .font(.caption)
            .textCase(.uppercase)

            // Frequency Visualizer
            if recorder.isRecording && !recorder.isInterrupted {
                FrequencyVisualizerView(level: recorder.audioLevel)
                    .frame(height: 60)
                    .padding(.horizontal, 24)
                    .transition(.opacity)
            } else {
                Color.clear
                    .frame(height: 60)
            }

            Spacer()

            // Control buttons
            HStack(spacing: 48) {
                // Pause/Resume button
                Button {
                    if recorder.isInterrupted {
                        recorder.resumeRecording()
                    } else {
                        recorder.pauseRecording()
                    }
                } label: {
                    Image(systemName: recorder.isInterrupted ? "play.fill" : "pause.fill")
                }
                .buttonStyle(VantaIconButtonStyle(size: 64, isPrimary: false))

                // Stop button
                Button(action: onStop) {
                    Image(systemName: "stop.fill")
                }
                .buttonStyle(VantaIconButtonStyle(size: 64, isPrimary: true))
            }
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .presentationDetents([.fraction(0.4)])
        .presentationDragIndicator(.hidden)
        .interactiveDismissDisabled(false)
    }

    private func formatTimeWithMilliseconds(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)

        return String(format: "%02d:%02d:%02d:%02d", hours, minutes, seconds, milliseconds)
    }
}

#Preview {
    struct PreviewWrapper: View {
        var body: some View {
            Color.gray
                .sheet(isPresented: .constant(true)) {
                    ActiveRecordingSheet(
                        preset: .dailyStandup,
                        onStop: {}
                    )
                    .environmentObject(AudioRecorder())
                }
        }
    }

    return PreviewWrapper()
}
