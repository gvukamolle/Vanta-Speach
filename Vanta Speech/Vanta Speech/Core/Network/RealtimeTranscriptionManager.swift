import Foundation
import Combine

/// Менеджер для real-time транскрипции чанков
/// Управляет очередью чанков, показывает предпревью от локальной диктовки,
/// и заменяет на серверную транскрипцию после получения ответа
@MainActor
final class RealtimeTranscriptionManager: ObservableObject {

    // MARK: - Published Properties

    /// Массив параграфов (каждый чанк = один параграф)
    @Published private(set) var paragraphs: [Paragraph] = []

    /// Текущий промежуточный текст (от локальной диктовки, ещё не отправлен)
    @Published var currentInterimText: String = ""

    /// Количество чанков в очереди на обработку
    @Published private(set) var pendingChunksCount: Int = 0

    /// Текущий статус менеджера
    @Published private(set) var status: Status = .idle

    // MARK: - Types

    struct Paragraph: Identifiable {
        let id: UUID
        var text: String
        var previewText: String  // Предпревью от локальной диктовки
        let timestamp: Date
        let duration: TimeInterval
        var status: ParagraphStatus

        enum ParagraphStatus {
            case transcribing  // Отправлено на сервер, ждём ответ
            case completed     // Получен ответ от сервера
            case failed        // Ошибка транскрипции
        }

        /// Текст для отображения: серверный если готов, иначе предпревью
        var displayText: String {
            switch status {
            case .transcribing:
                return previewText.isEmpty ? "..." : previewText
            case .completed:
                return text
            case .failed:
                return "[Ошибка транскрипции]"
            }
        }
    }

    enum Status {
        case idle
        case processing
        case error(String)
    }

    // MARK: - Private Properties

    private let transcriptionService = TranscriptionService()
    private var chunkQueue: [ChunkItem] = []
    private var isProcessing = false
    private var currentTask: Task<Void, Never>?

    private struct ChunkItem: Identifiable {
        let id: UUID
        let url: URL
        let duration: TimeInterval
        let timestamp: Date
        let previewText: String  // Текст от локальной диктовки
    }

    // MARK: - Public API

    /// Добавить чанк в очередь на транскрипцию
    /// - Parameters:
    ///   - url: URL аудиофайла
    ///   - duration: Длительность аудио
    ///   - previewText: Предварительный текст от локальной диктовки
    func enqueueChunk(url: URL, duration: TimeInterval, previewText: String) {
        let chunkId = UUID()
        let item = ChunkItem(
            id: chunkId,
            url: url,
            duration: duration,
            timestamp: Date(),
            previewText: previewText
        )
        chunkQueue.append(item)
        pendingChunksCount = chunkQueue.count

        // Добавляем параграф с предпревью
        let paragraph = Paragraph(
            id: chunkId,
            text: "",
            previewText: formatPreviewText(previewText),
            timestamp: item.timestamp,
            duration: duration,
            status: .transcribing
        )
        paragraphs.append(paragraph)

        // Очищаем текущий interim текст
        currentInterimText = ""

        print("[RealtimeTranscriptionManager] Chunk enqueued with preview: '\(previewText.prefix(30))...'")

        processNextChunkIfNeeded()
    }

    /// Получить финальный накопленный текст (только успешные параграфы)
    func getFinalTranscription() -> String {
        return paragraphs
            .filter { $0.status == .completed }
            .map { formatFinalText($0.text) }
            .joined(separator: "\n\n")
    }

    /// Сброс состояния
    func reset() {
        currentTask?.cancel()
        chunkQueue.removeAll()
        paragraphs.removeAll()
        currentInterimText = ""
        status = .idle
        pendingChunksCount = 0
        isProcessing = false
        print("[RealtimeTranscriptionManager] Reset")
    }

    /// Ожидание завершения всех pending транскрипций
    func waitForCompletion() async {
        while !chunkQueue.isEmpty || isProcessing {
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
        print("[RealtimeTranscriptionManager] All chunks processed")
    }

    /// Проверить есть ли еще чанки в обработке
    var hasProcessingChunks: Bool {
        !chunkQueue.isEmpty || isProcessing
    }

    /// Количество успешно обработанных параграфов
    var completedParagraphsCount: Int {
        paragraphs.filter { $0.status == .completed }.count
    }

    // MARK: - Private Methods

    private func processNextChunkIfNeeded() {
        guard !isProcessing, !chunkQueue.isEmpty else { return }

        isProcessing = true
        status = .processing

        let chunk = chunkQueue.removeFirst()
        pendingChunksCount = chunkQueue.count

        currentTask = Task {
            await processChunk(chunk)
            isProcessing = false

            // Продолжаем обработку если есть ещё чанки
            if !chunkQueue.isEmpty {
                processNextChunkIfNeeded()
            } else {
                status = .idle
            }
        }
    }

    private func processChunk(_ chunk: ChunkItem) async {
        print("[RealtimeTranscriptionManager] Processing chunk: \(chunk.url.lastPathComponent)")

        do {
            // Транскрибируем аудио через Whisper
            let result = try await transcriptionService.transcribeOnly(audioFileURL: chunk.url)

            // Форматируем результат: заглавная буква + точка
            let formattedResult = formatFinalText(result)

            // Обновляем параграф с серверным ответом
            if let index = paragraphs.firstIndex(where: { $0.id == chunk.id }) {
                paragraphs[index].text = formattedResult
                paragraphs[index].status = .completed
                print("[RealtimeTranscriptionManager] Chunk transcribed: '\(formattedResult.prefix(50))...'")
            }

            // Удаляем временный файл чанка
            try? FileManager.default.removeItem(at: chunk.url)

        } catch {
            print("[RealtimeTranscriptionManager] Failed to transcribe chunk: \(error)")

            // Помечаем параграф как failed
            if let index = paragraphs.firstIndex(where: { $0.id == chunk.id }) {
                paragraphs[index].status = .failed
            }

            status = .error(error.localizedDescription)

            // Удаляем файл даже при ошибке
            try? FileManager.default.removeItem(at: chunk.url)
        }
    }

    // MARK: - Text Formatting

    /// Форматирует предпревью текст (заглавная буква в начале)
    private func formatPreviewText(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        return capitalizeFirstLetter(trimmed)
    }

    /// Форматирует финальный текст (заглавная буква + точка в конце)
    private func formatFinalText(_ text: String) -> String {
        var trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        // Заглавная буква в начале
        trimmed = capitalizeFirstLetter(trimmed)

        // Точка в конце если нет знака препинания
        if !trimmed.hasSuffix(".") && !trimmed.hasSuffix("!") && !trimmed.hasSuffix("?") {
            trimmed += "."
        }

        return trimmed
    }

    /// Делает первую букву заглавной
    private func capitalizeFirstLetter(_ text: String) -> String {
        guard !text.isEmpty else { return text }
        return text.prefix(1).uppercased() + text.dropFirst()
    }
}
