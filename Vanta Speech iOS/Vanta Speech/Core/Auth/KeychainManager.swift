import Foundation
import Security

/// Manages secure storage of credentials in iOS Keychain
final class KeychainManager {
    static let shared = KeychainManager()

    private let service = "com.vanta.speech"
    private let sessionKey = "user_session"
    private let ewsCredentialsKey = "ews_credentials"
    private let googleRefreshTokenKey = "google_refresh_token"
    private let googleUserInfoKey = "google_user_info"

    private init() {}

    // MARK: - Session Storage

    func saveSession(_ session: UserSession) throws {
        let data = try JSONEncoder().encode(session)
        try save(data: data, forKey: sessionKey)
    }

    func loadSession() -> UserSession? {
        guard let data = load(forKey: sessionKey) else { return nil }
        return try? JSONDecoder().decode(UserSession.self, from: data)
    }

    func deleteSession() {
        delete(forKey: sessionKey)
    }

    // MARK: - EWS Credentials Storage

    /// Save EWS credentials for Exchange Server authentication
    func saveEWSCredentials(_ credentials: EWSCredentials) throws {
        let data = try JSONEncoder().encode(credentials)
        try save(data: data, forKey: ewsCredentialsKey)
    }

    /// Load saved EWS credentials
    func loadEWSCredentials() -> EWSCredentials? {
        guard let data = load(forKey: ewsCredentialsKey) else { return nil }
        return try? JSONDecoder().decode(EWSCredentials.self, from: data)
    }

    /// Delete EWS credentials
    func deleteEWSCredentials() {
        delete(forKey: ewsCredentialsKey)
    }

    /// Check if EWS credentials are stored
    var hasEWSCredentials: Bool {
        loadEWSCredentials() != nil
    }

    // MARK: - Google OAuth Storage

    /// Save Google refresh token
    func saveGoogleRefreshToken(_ token: String) throws {
        guard let data = token.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }
        try save(data: data, forKey: googleRefreshTokenKey)
    }

    /// Load Google refresh token
    func loadGoogleRefreshToken() -> String? {
        guard let data = load(forKey: googleRefreshTokenKey) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Delete Google refresh token
    func deleteGoogleRefreshToken() {
        delete(forKey: googleRefreshTokenKey)
    }

    /// Save Google user info (email, name)
    func saveGoogleUserInfo(_ info: GoogleUserInfo) throws {
        let dict: [String: String?] = [
            "email": info.email,
            "displayName": info.displayName,
            "profileImageURL": info.profileImageURL?.absoluteString
        ]
        let data = try JSONEncoder().encode(dict)
        try save(data: data, forKey: googleUserInfoKey)
    }

    /// Load Google user info
    func loadGoogleUserInfo() -> GoogleUserInfo? {
        guard let data = load(forKey: googleUserInfoKey),
              let dict = try? JSONDecoder().decode([String: String?].self, from: data),
              let email = dict["email"] ?? nil else {
            return nil
        }
        return GoogleUserInfo(
            email: email,
            displayName: dict["displayName"] ?? nil,
            profileImageURL: (dict["profileImageURL"] ?? nil).flatMap { URL(string: $0) }
        )
    }

    /// Delete all Google credentials
    func deleteGoogleCredentials() {
        delete(forKey: googleRefreshTokenKey)
        delete(forKey: googleUserInfoKey)
    }

    /// Check if Google credentials are stored
    var hasGoogleCredentials: Bool {
        loadGoogleRefreshToken() != nil
    }

    // MARK: - Generic Keychain Operations

    private func save(data: Data, forKey key: String) throws {
        // Delete any existing item first
        delete(forKey: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    private func load(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    private func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }

    enum KeychainError: LocalizedError {
        case saveFailed(OSStatus)
        case encodingFailed

        var errorDescription: String? {
            switch self {
            case .saveFailed(let status):
                return "Failed to save to Keychain: \(status)"
            case .encodingFailed:
                return "Failed to encode data for Keychain"
            }
        }
    }
}
