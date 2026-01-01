import Foundation

/// Service for Google Docs API v1 operations
actor GoogleDocsService {
    private let baseURL = IntegrationConfig.Google.docsAPIBaseURL
    private let authManager: GoogleAuthManager

    init(authManager: GoogleAuthManager = .shared) {
        self.authManager = authManager
    }

    // MARK: - Create Document

    /// Create a new Google Doc with the specified title
    /// - Parameter title: Document title
    /// - Returns: Created document info
    func createDocument(title: String) async throws -> GoogleDocument {
        let accessToken = try await authManager.getValidAccessToken()

        guard let url = URL(string: "\(baseURL)/documents") else {
            throw GoogleDocsError.invalidConfiguration
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["title": title]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)

        return try JSONDecoder().decode(GoogleDocument.self, from: data)
    }

    // MARK: - Insert Content

    /// Insert text content into a document
    /// - Parameters:
    ///   - documentId: Target document ID
    ///   - text: Text to insert
    ///   - index: Position to insert at (1 = beginning after title)
    func insertText(documentId: String, text: String, at index: Int = 1) async throws {
        let requests = [
            DocumentRequest(
                insertText: InsertTextRequest(
                    location: DocumentLocation(index: index),
                    text: text
                )
            )
        ]

        try await batchUpdate(documentId: documentId, requests: requests)
    }

    /// Add formatted content with heading
    /// - Parameters:
    ///   - documentId: Target document ID
    ///   - heading: Heading text
    ///   - content: Body content
    func insertFormattedContent(
        documentId: String,
        heading: String,
        content: String
    ) async throws {
        let headingText = heading + "\n\n"
        let fullText = headingText + content + "\n"

        var requests: [DocumentRequest] = []

        // Insert all text first
        requests.append(DocumentRequest(
            insertText: InsertTextRequest(
                location: DocumentLocation(index: 1),
                text: fullText
            )
        ))

        // Style the heading as HEADING_1
        requests.append(DocumentRequest(
            updateParagraphStyle: UpdateParagraphStyleRequest(
                range: DocumentRange(startIndex: 1, endIndex: headingText.count),
                paragraphStyle: ParagraphStyle(namedStyleType: "HEADING_1"),
                fields: "namedStyleType"
            )
        ))

        try await batchUpdate(documentId: documentId, requests: requests)
    }

    // MARK: - Batch Update

    /// Execute batch update on document
    func batchUpdate(documentId: String, requests: [DocumentRequest]) async throws {
        let accessToken = try await authManager.getValidAccessToken()

        guard let url = URL(string: "\(baseURL)/documents/\(documentId):batchUpdate") else {
            throw GoogleDocsError.invalidConfiguration
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let batchRequest = BatchUpdateRequest(requests: requests)
        request.httpBody = try JSONEncoder().encode(batchRequest)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
    }

    // MARK: - Response Validation

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GoogleDocsError.networkError(URLError(.badServerResponse))
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw GoogleDocsError.tokenRefreshFailed
        case 403:
            throw GoogleDocsError.folderAccessDenied
        case 429:
            throw GoogleDocsError.rateLimitExceeded
        default:
            if let apiError = try? JSONDecoder().decode(GoogleAPIError.self, from: data) {
                throw GoogleDocsError.apiError(
                    code: apiError.error.code,
                    message: apiError.error.message
                )
            }
            throw GoogleDocsError.apiError(
                code: httpResponse.statusCode,
                message: "Unknown error"
            )
        }
    }
}

// MARK: - Meeting Summary Helper

extension GoogleDocsService {

    /// Create a document with meeting summary
    /// - Parameters:
    ///   - title: Meeting title (becomes document title)
    ///   - summary: AI-generated summary
    ///   - transcription: Optional full transcription
    ///   - date: Meeting date
    /// - Returns: Created document with URL
    func createMeetingSummaryDocument(
        title: String,
        summary: String,
        transcription: String? = nil,
        date: Date = Date()
    ) async throws -> GoogleDocument {
        // Create document
        let document = try await createDocument(title: title)

        // Build content
        var content = ""

        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ru_RU")

        content += "Дата: \(formatter.string(from: date))\n\n"
        content += "Краткое содержание\n\n"
        content += summary + "\n\n"

        if let transcription = transcription, !transcription.isEmpty {
            content += "─".repeating(40) + "\n\n"
            content += "Полная транскрипция\n\n"
            content += transcription + "\n\n"
        }

        content += "─".repeating(40) + "\n"
        content += "Создано в Vanta Speech\n"

        // Insert content
        try await insertText(documentId: document.documentId, text: content)

        return document
    }
}

// MARK: - String Extension

private extension String {
    func repeating(_ count: Int) -> String {
        String(repeating: self, count: count)
    }
}
