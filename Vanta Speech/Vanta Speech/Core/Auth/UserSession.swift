import Foundation

/// Represents an authenticated user session
struct UserSession: Codable {
    let username: String
    let displayName: String?
    let email: String?
    let authenticatedAt: Date

    init(username: String, displayName: String? = nil, email: String? = nil) {
        self.username = username
        self.displayName = displayName
        self.email = email
        self.authenticatedAt = Date()
    }
}
