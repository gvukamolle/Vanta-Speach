import SwiftUI
import SwiftData

struct RecordingView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var recorder = AudioRecorder()
    @State private var recordingTitle = ""
    @State private var currentRecordingURL: URL?
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()

                // Timer Display
                Text(formatTime(recorder.recordingDuration))
                    .font(.system(size: 64, weight: .light, design: .monospaced))
                    .foregroundStyle(recorder.isRecording ? .red : .primary)

                // Audio Level Indicator
                if recorder.isRecording {
                    AudioLevelView(level: recorder.audioLevel)
                        .frame(height: 60)
                        .padding(.horizontal, 40)
                }

                Spacer()

                // Recording Controls
                HStack(spacing: 60) {
                    if recorder.isRecording {
                        // Stop Button
                        Button(action: stopRecording) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.white)
                                .frame(width: 80, height: 80)
                                .background(.red)
                                .clipShape(Circle())
                        }
                    } else {
                        // Record Button
                        Button(action: startRecording) {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.white)
                                .frame(width: 80, height: 80)
                                .background(.red)
                                .clipShape(Circle())
                        }
                    }
                }

                Spacer()
            }
            .navigationTitle("Record")
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func startRecording() {
        Task {
            do {
                currentRecordingURL = try await recorder.startRecording()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func stopRecording() {
        guard let result = recorder.stopRecording() else { return }

        let title = "Meeting \(Date().formatted(date: .abbreviated, time: .shortened))"

        let recording = Recording(
            title: title,
            duration: result.duration,
            audioFileURL: result.url.path
        )

        modelContext.insert(recording)
        currentRecordingURL = nil
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

struct AudioLevelView: View {
    let level: Float

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(0..<30, id: \.self) { index in
                    let threshold = Float(index) / 30.0
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor(for: index))
                        .opacity(level > threshold ? 1.0 : 0.3)
                }
            }
        }
    }

    private func barColor(for index: Int) -> Color {
        let ratio = Float(index) / 30.0
        if ratio < 0.6 {
            return .green
        } else if ratio < 0.8 {
            return .yellow
        } else {
            return .red
        }
    }
}

#Preview {
    RecordingView()
}
