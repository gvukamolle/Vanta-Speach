import SwiftUI
import SwiftData
import Combine

struct RecordingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject var recorder: AudioRecorder

    @State private var showRecordingSheet = false
    @State private var selectedPreset: RecordingPreset?
    @State private var currentRecordingURL: URL?
    @State private var showError = false
    @State private var errorMessage = ""

    @StateObject private var presetSettings = PresetSettings.shared

    var body: some View {
        NavigationStack {
            ZStack {
                // Decorative background
                VantaDecorativeBackground()
                    .ignoresSafeArea()

                // Main content
                ScrollView {
                    VStack(spacing: 16) {
                        // Active recording banner
                        if recorder.isRecording {
                            activeRecordingBanner
                        }

                        // Today's recordings
                        TodayRecordingsSection()
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
                .background(Color(.systemGroupedBackground).opacity(0.9))

                // Floating microphone button
                VStack {
                    Spacer()
                    microphoneButton
                        .padding(.bottom, 24)
                }
            }
            .navigationTitle("Запись")
            .sheet(isPresented: $showRecordingSheet) {
                if let preset = selectedPreset {
                    ActiveRecordingSheet(preset: preset, onStop: stopRecording)
                }
            }
            .alert("Ошибка", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Active Recording Banner

    private var activeRecordingBanner: some View {
        Button {
            showRecordingSheet = true
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.pinkVibrant)
                    .frame(width: 10, height: 10)
                    .modifier(PulseAnimation())

                Text("Идёт запись")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text(formatTime(recorder.recordingDuration))
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(.secondary)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.pinkVibrant.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Microphone Button

    @ViewBuilder
    private var microphoneButton: some View {
        if recorder.isRecording {
            // If recording - tapping opens the sheet
            Button {
                showRecordingSheet = true
            } label: {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.pinkVibrant)
                        .frame(width: 8, height: 8)
                        .modifier(PulseAnimation())

                    Image(systemName: "waveform")

                    Text(formatTime(recorder.recordingDuration))
                        .monospacedDigit()
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .vantaGlassProminent(cornerRadius: 24)
            }
            .buttonStyle(.plain)
        } else {
            // If not recording - show menu with presets (or direct record if only one)
            if presetSettings.enabledPresets.count == 1, let singlePreset = presetSettings.enabledPresets.first {
                // Only one preset enabled - start recording directly
                Button {
                    startRecordingWithPreset(singlePreset)
                } label: {
                    HStack(spacing: 8) {
                        if recorder.isConverting {
                            ProgressView()
                                .tint(.primary)
                        } else {
                            Image(systemName: "mic.fill")
                                .font(.title3)
                        }

                        Text("Записать")
                            .font(.body)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .vantaGlassProminent(cornerRadius: 28)
                }
                .buttonStyle(.plain)
                .disabled(recorder.isConverting)
            } else {
                // Multiple presets - show menu
                Menu {
                    ForEach(presetSettings.enabledPresets, id: \.rawValue) { preset in
                        Button {
                            startRecordingWithPreset(preset)
                        } label: {
                            Label(preset.displayName, systemImage: preset.icon)
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        if recorder.isConverting {
                            ProgressView()
                                .tint(.primary)
                        } else {
                            Image(systemName: "mic.fill")
                                .font(.title3)
                        }

                        Text("Записать")
                            .font(.body)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .vantaGlassProminent(cornerRadius: 28)
                }
                .buttonStyle(.plain)
                .disabled(recorder.isConverting)
            }
        }
    }

    // MARK: - Actions

    private func startRecordingWithPreset(_ preset: RecordingPreset) {
        selectedPreset = preset

        Task {
            do {
                currentRecordingURL = try await recorder.startRecording()
                showRecordingSheet = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func stopRecording() {
        showRecordingSheet = false

        Task {
            let result = await recorder.stopRecording(convertToOGG: true)

            switch result {
            case .success(let data):
                let presetName = selectedPreset?.displayName ?? "Запись"
                let title = "\(presetName) \(Date().formatted(date: .abbreviated, time: .shortened))"

                let recording = Recording(
                    title: title,
                    duration: data.duration,
                    audioFileURL: data.url.path,
                    preset: selectedPreset
                )

                modelContext.insert(recording)
                currentRecordingURL = nil
                selectedPreset = nil

            case .failure(let error):
                errorMessage = error.localizedDescription
                showError = true
            }
        }
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

// MARK: - Pulse Animation

struct PulseAnimation: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.2 : 1.0)
            .opacity(isPulsing ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear {
                isPulsing = true
            }
    }
}

// MARK: - Conveyor Waveform View (Vertical bars like Voice Memos)

struct FrequencyVisualizerView: View {
    let level: Float
    private let barCount = 80
    @State private var samples: [CGFloat] = []

    private let timer = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()

    init(level: Float) {
        self.level = level
        _samples = State(initialValue: Array(repeating: 0.05, count: barCount))
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 1.5) {
                ForEach(0..<samples.count, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 0.5)
                        .fill(Color.pinkVibrant.opacity(0.85))
                        .frame(
                            width: 2,
                            height: max(2, samples[index] * geometry.size.height)
                        )
                        .animation(.easeOut(duration: 0.08), value: samples[index])
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .onReceive(timer) { _ in
            updateSamples()
        }
    }

    private func updateSamples() {
        var newSamples = samples
        newSamples.removeFirst()

        let baseHeight = CGFloat(level)
        let variation = CGFloat.random(in: 0.85...1.15)
        let newValue = min(1.0, max(0.03, baseHeight * variation))

        newSamples.append(newValue)
        samples = newSamples
    }
}

// MARK: - Audio Level View (Legacy - kept for compatibility)

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
        .environmentObject(AudioRecorder())
        .modelContainer(for: Recording.self, inMemory: true)
}
