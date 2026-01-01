import Foundation

// MARK: - Google Document

/// Represents a Google Docs document
struct GoogleDocument: Identifiable, Codable {
    let documentId: String
    let title: String
    let revisionId: String?

    var id: String { documentId }

    /// URL to open document in browser/app
    var webViewLink: String {
        "https://docs.google.com/document/d/\(documentId)/edit"
    }

    var url: URL? {
        URL(string: webViewLink)
    }
}

// MARK: - Drive Folder

/// Represents a folder in Google Drive
struct DriveFolder: Identifiable, Codable {
    let id: String
    let name: String
    let mimeType: String?
    let iconLink: String?
    let modifiedTime: Date?

    static let rootFolderID = "root"
}

// MARK: - Drive File List Response

struct DriveFileListResponse: Codable {
    let files: [DriveFolder]
    let nextPageToken: String?
}

// MARK: - Batch Update Models

/// Request to update document content
struct BatchUpdateRequest: Codable {
    let requests: [DocumentRequest]
}

struct DocumentRequest: Codable {
    var insertText: InsertTextRequest?
    var updateParagraphStyle: UpdateParagraphStyleRequest?
    var deleteContentRange: DeleteContentRangeRequest?
}

struct InsertTextRequest: Codable {
    let location: DocumentLocation
    let text: String
}

struct DocumentLocation: Codable {
    let index: Int
}

struct UpdateParagraphStyleRequest: Codable {
    let range: DocumentRange
    let paragraphStyle: ParagraphStyle
    let fields: String
}

struct DeleteContentRangeRequest: Codable {
    let range: DocumentRange
}

struct DocumentRange: Codable {
    let startIndex: Int
    let endIndex: Int
}

struct ParagraphStyle: Codable {
    let namedStyleType: String // TITLE, HEADING_1, HEADING_2, NORMAL_TEXT
}

// MARK: - API Error Response

struct GoogleAPIError: Codable {
    let error: GoogleErrorDetails
}

struct GoogleErrorDetails: Codable {
    let code: Int
    let message: String
    let status: String?
}

// MARK: - Google Docs Errors

enum GoogleDocsError: LocalizedError {
    case notSignedIn
    case tokenRefreshFailed
    case invalidConfiguration
    case documentCreationFailed(String)
    case documentUpdateFailed(String)
    case folderAccessDenied
    case folderNotFound
    case networkError(Error)
    case apiError(code: Int, message: String)
    case rateLimitExceeded

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "Не выполнен вход в Google"
        case .tokenRefreshFailed:
            return "Не удалось обновить токен авторизации"
        case .invalidConfiguration:
            return "Некорректная конфигурация Google API"
        case .documentCreationFailed(let message):
            return "Ошибка создания документа: \(message)"
        case .documentUpdateFailed(let message):
            return "Ошибка обновления документа: \(message)"
        case .folderAccessDenied:
            return "Нет доступа к папке"
        case .folderNotFound:
            return "Папка не найдена"
        case .networkError(let error):
            return "Сетевая ошибка: \(error.localizedDescription)"
        case .apiError(let code, let message):
            return "Ошибка Google API (\(code)): \(message)"
        case .rateLimitExceeded:
            return "Превышен лимит запросов. Попробуйте позже."
        }
    }
}

// MARK: - User Info

/// Google user profile info
struct GoogleUserInfo {
    let email: String
    let displayName: String?
    let profileImageURL: URL?
}
