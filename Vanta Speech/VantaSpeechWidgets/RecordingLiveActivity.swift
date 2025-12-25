import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

struct RecordingLiveActivityWidget: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RecordingActivityAttributes.self) { context in
            // Lock Screen / Banner View
            LockScreenLiveActivityView(context: context)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded View
                expandedContent(context: context)
            } compactLeading: {
                compactLeadingView(context: context)
            } compactTrailing: {
                compactTrailingView(context: context)
            } minimal: {
                minimalView(context: context)
            }
        }
    }

    // MARK: - Dynamic Island Expanded

    @DynamicIslandExpandedContentBuilder
    private func expandedContent(
        context: ActivityViewContext<RecordingActivityAttributes>
    ) -> DynamicIslandExpandedContent<some View> {

        DynamicIslandExpandedRegion(.leading) {
            HStack(spacing: 8) {
                Image(systemName: context.state.status.systemImage)
                    .font(.title3)
                    .foregroundStyle(statusColor(context.state.status))

                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.status.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text(context.attributes.presetName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }

        DynamicIslandExpandedRegion(.trailing) {
            Text(formatDuration(context.state.duration))
                .font(.title2)
                .fontWeight(.bold)
                .monospacedDigit()
        }

        DynamicIslandExpandedRegion(.bottom) {
            ExpandedBottomView(context: context)
        }
    }

    // MARK: - Compact Views

    @ViewBuilder
    private func compactLeadingView(
        context: ActivityViewContext<RecordingActivityAttributes>
    ) -> some View {
        HStack(spacing: 4) {
            Image(systemName: context.state.status.systemImage)
                .font(.caption)
                .foregroundStyle(statusColor(context.state.status))

            if context.state.status == .recording {
                // Пульсирующая точка
                Circle()
                    .fill(.red)
                    .frame(width: 6, height: 6)
            }
        }
    }

    @ViewBuilder
    private func compactTrailingView(
        context: ActivityViewContext<RecordingActivityAttributes>
    ) -> some View {
        switch context.state.status {
        case .recording, .paused, .stopped:
            Text(formatDuration(context.state.duration))
                .font(.caption)
                .fontWeight(.semibold)
                .monospacedDigit()

        case .transcribing:
            ProgressView()
                .scaleEffect(0.6)

        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
        }
    }

    @ViewBuilder
    private func minimalView(
        context: ActivityViewContext<RecordingActivityAttributes>
    ) -> some View {
        switch context.state.status {
        case .recording:
            Image(systemName: "waveform")
                .foregroundStyle(.pink)
        case .paused:
            Image(systemName: "pause.fill")
                .foregroundStyle(.blue)
        case .stopped:
            Image(systemName: "stop.fill")
                .foregroundStyle(.orange)
        case .transcribing:
            Image(systemName: "sparkles")
                .foregroundStyle(.purple)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
    }

    // MARK: - Helpers

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func statusColor(_ status: RecordingActivityStatus) -> Color {
        switch status {
        case .recording: return .pink
        case .paused: return .blue
        case .stopped: return .orange
        case .transcribing: return .purple
        case .completed: return .green
        }
    }
}

// MARK: - Expanded Bottom View with Haptic

/// Обёртка для bottom content Dynamic Island
struct ExpandedBottomView: View {
    let context: ActivityViewContext<RecordingActivityAttributes>

    var body: some View {
        expandedBottomContent
    }

    @ViewBuilder
    private var expandedBottomContent: some View {
        switch context.state.status {
        case .recording, .paused:
            // Кнопки управления записью
            HStack(spacing: 24) {
                // Pause / Resume
                if context.state.status == .recording {
                    Button(intent: PauseRecordingIntent()) {
                        Image(systemName: "pause.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.blue.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(intent: ResumeRecordingIntent()) {
                        Image(systemName: "play.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.green.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }

                // Stop
                Button(intent: StopRecordingIntent()) {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .foregroundStyle(.red)
                        .frame(width: 44, height: 44)
                        .background(Color.red.opacity(0.2))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 8)

        case .stopped:
            // Кнопки "Сделать саммари" и "Отлично"
            HStack(spacing: 12) {
                // Кнопка "Отлично" - закрыть без транскрипции
                Button(intent: DismissActivityIntent()) {
                    Text("Отлично")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.3))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                // Кнопка "Сделать саммари"
                Button(intent: StartTranscriptionIntent()) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.body)
                        Text("Саммари")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 8)

        case .transcribing:
            // Прогресс транскрипции с кнопкой "Скрыть"
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    ProgressView(value: context.state.transcriptionProgress ?? 0)
                        .tint(.purple)
                        .frame(height: 4)

                    HStack {
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundStyle(.purple)
                        Text("Создаём саммари...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Кнопка "Скрыть"
                Button(intent: HideActivityIntent()) {
                    Text("Скрыть")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.3))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 8)

        case .completed:
            // Статус "Готово"
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
                Text("Саммари готово")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Lock Screen View

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<RecordingActivityAttributes>

    var body: some View {
        HStack(spacing: 12) {
            // Status icon with preset
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: context.attributes.presetIcon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(context.attributes.presetName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    Text(context.state.status.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Duration or Progress
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatDuration(context.state.duration))
                    .font(.title2)
                    .fontWeight(.bold)
                    .monospacedDigit()

                if let progress = context.state.transcriptionProgress {
                    ProgressView(value: progress)
                        .frame(width: 60)
                        .tint(.purple)
                }
            }

            // Action button
            actionButton
        }
        .padding(16)
        .background(Color.black.opacity(0.8))
    }

    @ViewBuilder
    private var actionButton: some View {
        switch context.state.status {
        case .recording:
            Button(intent: PauseRecordingIntent()) {
                Image(systemName: "pause.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.blue.opacity(0.3))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

        case .paused:
            Button(intent: ResumeRecordingIntent()) {
                Image(systemName: "play.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.green.opacity(0.3))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

        case .stopped:
            HStack(spacing: 8) {
                Button(intent: DismissActivityIntent()) {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.gray.opacity(0.3))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Button(intent: StartTranscriptionIntent()) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundStyle(.purple)
                        .frame(width: 32, height: 32)
                        .background(Color.purple.opacity(0.2))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

        case .transcribing:
            Button(intent: HideActivityIntent()) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.gray.opacity(0.3))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.green)
                .frame(width: 40, height: 40)
        }
    }

    private var statusColor: Color {
        switch context.state.status {
        case .recording: return .pink
        case .paused: return .blue
        case .stopped: return .orange
        case .transcribing: return .purple
        case .completed: return .green
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
