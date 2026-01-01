import Foundation

/// Service for Google Drive API v3 operations (folders)
actor GoogleDriveService {
    private let baseURL = IntegrationConfig.Google.driveAPIBaseURL
    private let authManager: GoogleAuthManager

    init(authManager: GoogleAuthManager = .shared) {
        self.authManager = authManager
    }

    // MARK: - List Folders

    /// Get list of folders in a parent folder
    /// - Parameter parentId: Parent folder ID ("root" for Drive root)
    /// - Returns: Array of folders
    func listFolders(parentId: String = DriveFolder.rootFolderID) async throws -> [DriveFolder] {
        let accessToken = try await authManager.getValidAccessToken()

        var components = URLComponents(string: "\(baseURL)/files")!
        components.queryItems = [
            URLQueryItem(
                name: "q",
                value: "mimeType='application/vnd.google-apps.folder' and '\(parentId)' in parents and trashed=false"
            ),
            URLQueryItem(name: "fields", value: "files(id,name,mimeType,iconLink,modifiedTime),nextPageToken"),
            URLQueryItem(name: "orderBy", value: "name"),
            URLQueryItem(name: "pageSize", value: "100")
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let result = try decoder.decode(DriveFileListResponse.self, from: data)
        return result.files
    }

    // MARK: - Move File to Folder

    /// Move a file to a different folder
    /// - Parameters:
    ///   - fileId: File to move (document ID)
    ///   - folderId: Destination folder ID
    func moveToFolder(fileId: String, folderId: String) async throws {
        let accessToken = try await authManager.getValidAccessToken()

        // First, get current parents
        let currentParents = try await getFileParents(fileId: fileId)
        let previousParents = currentParents.joined(separator: ",")

        // Move file
        var components = URLComponents(string: "\(baseURL)/files/\(fileId)")!
        components.queryItems = [
            URLQueryItem(name: "addParents", value: folderId),
            URLQueryItem(name: "removeParents", value: previousParents),
            URLQueryItem(name: "fields", value: "id,parents")
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: nil)
    }

    // MARK: - Get File Parents

    private func getFileParents(fileId: String) async throws -> [String] {
        let accessToken = try await authManager.getValidAccessToken()

        var components = URLComponents(string: "\(baseURL)/files/\(fileId)")!
        components.queryItems = [
            URLQueryItem(name: "fields", value: "parents")
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)

        struct FileParents: Codable {
            let parents: [String]?
        }

        let result = try JSONDecoder().decode(FileParents.self, from: data)
        return result.parents ?? []
    }

    // MARK: - Create Folder

    /// Create a new folder
    /// - Parameters:
    ///   - name: Folder name
    ///   - parentId: Parent folder ID
    /// - Returns: Created folder
    func createFolder(name: String, parentId: String = DriveFolder.rootFolderID) async throws -> DriveFolder {
        let accessToken = try await authManager.getValidAccessToken()

        guard let url = URL(string: "\(baseURL)/files") else {
            throw GoogleDocsError.invalidConfiguration
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "name": name,
            "mimeType": "application/vnd.google-apps.folder",
            "parents": [parentId]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)

        return try JSONDecoder().decode(DriveFolder.self, from: data)
    }

    // MARK: - Response Validation

    private func validateResponse(_ response: URLResponse, data: Data?) throws {
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
        case 404:
            throw GoogleDocsError.folderNotFound
        case 429:
            throw GoogleDocsError.rateLimitExceeded
        default:
            if let data = data,
               let apiError = try? JSONDecoder().decode(GoogleAPIError.self, from: data) {
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
