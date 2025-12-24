import Foundation

/// Service for authenticating against Active Directory via LDAP
actor LDAPAuthService {
    // MARK: - Hardcoded LDAP Configuration

    private static let ldapHost = "10.64.248.19"
    private static let ldapPort = 389
    private static let ldapBaseDN = "OU=MainOffice,DC=b2pos,DC=local"
    private static let ldapUserSearchFilter = "(&(objectCategory=Person)(sAMAccountName=*))"
    private static let useLDAPS = false

    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    // MARK: - Authentication

    enum AuthError: LocalizedError {
        case invalidCredentials
        case connectionFailed(String)
        case serverError(String)
        case timeout
        case streamError(String)
        case writeError(Int, Int)
        case readError

        var errorDescription: String? {
            switch self {
            case .invalidCredentials:
                return "Неверный логин или пароль (LDAP resultCode != 0)"
            case .connectionFailed(let details):
                return "Не удалось подключиться к серверу LDAP. \(details)"
            case .serverError(let message):
                return "Ошибка сервера: \(message)"
            case .timeout:
                return "Превышено время ожидания подключения к LDAP"
            case .streamError(let details):
                return "Ошибка потока данных: \(details)"
            case .writeError(let written, let expected):
                return "Ошибка отправки запроса: записано \(written) из \(expected) байт"
            case .readError:
                return "Ошибка чтения ответа от LDAP сервера (0 байт)"
            }
        }
    }

    /// Authenticate user against LDAP/AD
    /// - Parameters:
    ///   - username: sAMAccountName (e.g., "ivanov")
    ///   - password: User's AD password
    /// - Returns: UserSession on success
    func authenticate(username: String, password: String) async throws -> UserSession {
        // Construct the bind DN from username
        // Format: username@domain or DOMAIN\username or full DN
        let bindDN = "\(username)@b2pos.local"

        // For direct LDAP auth, we would use a library like OpenLDAP
        // Since iOS doesn't have native LDAP, we have two options:
        // 1. Use a backend auth proxy (recommended)
        // 2. Use a third-party LDAP library

        // Option 1: Backend Auth Proxy (implement when backend is ready)
        // return try await authenticateViaProxy(username: username, password: password)

        // Option 2: Simple LDAP bind attempt via TCP (basic implementation)
        // This is a simplified version - in production, use proper LDAP library
        return try await performLDAPBind(bindDN: bindDN, password: password, username: username)
    }

    // MARK: - LDAP Bind Implementation

    private func performLDAPBind(bindDN: String, password: String, username: String) async throws -> UserSession {
        // Create LDAP bind request
        // This is a simplified implementation using raw TCP socket approach
        // For production, consider using a proper LDAP library or backend proxy

        let host = Self.ldapHost
        let port = Self.ldapPort

        return try await withCheckedThrowingContinuation { continuation in
            var inputStream: InputStream?
            var outputStream: OutputStream?

            Stream.getStreamsToHost(
                withName: host,
                port: port,
                inputStream: &inputStream,
                outputStream: &outputStream
            )

            guard let input = inputStream, let output = outputStream else {
                continuation.resume(throwing: AuthError.connectionFailed("Не удалось создать потоки к \(host):\(port)"))
                return
            }

            input.open()
            output.open()

            // Check stream status
            if input.streamStatus == .error {
                let errorDesc = input.streamError?.localizedDescription ?? "unknown"
                input.close()
                output.close()
                continuation.resume(throwing: AuthError.streamError("Input stream error: \(errorDesc)"))
                return
            }

            if output.streamStatus == .error {
                let errorDesc = output.streamError?.localizedDescription ?? "unknown"
                input.close()
                output.close()
                continuation.resume(throwing: AuthError.streamError("Output stream error: \(errorDesc)"))
                return
            }

            // Build LDAP Simple Bind Request
            let bindRequest = buildLDAPBindRequest(bindDN: bindDN, password: password)

            // Send request
            let bytesWritten = bindRequest.withUnsafeBytes { buffer in
                output.write(buffer.bindMemory(to: UInt8.self).baseAddress!, maxLength: bindRequest.count)
            }

            guard bytesWritten == bindRequest.count else {
                input.close()
                output.close()
                continuation.resume(throwing: AuthError.writeError(bytesWritten, bindRequest.count))
                return
            }

            // Read response
            var responseBuffer = [UInt8](repeating: 0, count: 1024)
            let bytesRead = input.read(&responseBuffer, maxLength: responseBuffer.count)

            input.close()
            output.close()

            guard bytesRead > 0 else {
                continuation.resume(throwing: AuthError.readError)
                return
            }

            // Parse LDAP Bind Response
            let responseData = Data(responseBuffer.prefix(bytesRead))
            let parseResult = parseLDAPBindResponse(response: responseData)

            if parseResult.success {
                let session = UserSession(
                    username: username,
                    displayName: username,
                    email: nil
                )
                continuation.resume(returning: session)
            } else {
                let errorMsg = "resultCode=\(parseResult.resultCode), \(parseResult.errorMessage), bytes=\(bytesRead), hex=\(responseData.prefix(50).map { String(format: "%02X", $0) }.joined(separator: " "))"
                continuation.resume(throwing: AuthError.serverError(errorMsg))
            }
        }
    }

    // MARK: - LDAP Protocol Helpers

    /// Build LDAP Simple Bind Request (ASN.1 BER encoded)
    private func buildLDAPBindRequest(bindDN: String, password: String) -> Data {
        var request = Data()

        // Message ID (integer, value = 1)
        let messageID: [UInt8] = [0x02, 0x01, 0x01]

        // Bind Request (application 0)
        var bindRequestContent = Data()

        // Version (integer, value = 3 for LDAPv3)
        bindRequestContent.append(contentsOf: [0x02, 0x01, 0x03])

        // Bind DN (octet string)
        let bindDNBytes = bindDN.data(using: .utf8) ?? Data()
        bindRequestContent.append(0x04) // Octet string tag
        bindRequestContent.append(contentsOf: encodeLength(bindDNBytes.count))
        bindRequestContent.append(bindDNBytes)

        // Simple authentication (context-specific 0)
        let passwordBytes = password.data(using: .utf8) ?? Data()
        bindRequestContent.append(0x80) // Context-specific primitive tag 0
        bindRequestContent.append(contentsOf: encodeLength(passwordBytes.count))
        bindRequestContent.append(passwordBytes)

        // Wrap in Bind Request sequence (application 0)
        var bindRequest = Data()
        bindRequest.append(0x60) // Application 0 (Bind Request)
        bindRequest.append(contentsOf: encodeLength(bindRequestContent.count))
        bindRequest.append(bindRequestContent)

        // Build complete message
        var messageContent = Data()
        messageContent.append(contentsOf: messageID)
        messageContent.append(bindRequest)

        // Wrap in LDAP Message sequence
        request.append(0x30) // Sequence tag
        request.append(contentsOf: encodeLength(messageContent.count))
        request.append(messageContent)

        return request
    }

    /// Encode ASN.1 BER length
    private func encodeLength(_ length: Int) -> [UInt8] {
        if length < 128 {
            return [UInt8(length)]
        } else if length < 256 {
            return [0x81, UInt8(length)]
        } else {
            return [0x82, UInt8(length >> 8), UInt8(length & 0xFF)]
        }
    }

    /// Parse LDAP Bind Response and extract result code
    private func parseLDAPBindResponse(response: Data) -> (success: Bool, resultCode: Int, errorMessage: String) {
        // Parse ASN.1 BER encoded LDAP Bind Response
        // Looking for resultCode

        guard response.count > 10 else {
            return (false, -1, "Response too short (\(response.count) bytes)")
        }

        // Find the result code in the response
        // Response format: SEQUENCE { messageID, bindResponse { resultCode, matchedDN, diagnosticMessage } }
        // Result codes: 0 = success, 49 = invalidCredentials, 52 = unavailable, etc.

        let bytes = [UInt8](response)

        // Look for enumerated tag (0x0A) which contains the result code
        for i in 0..<(bytes.count - 2) {
            if bytes[i] == 0x0A && bytes[i + 1] == 0x01 {
                // Found enumerated value (result code)
                let resultCode = Int(bytes[i + 2])
                let errorMsg = ldapResultCodeDescription(resultCode)
                return (resultCode == 0, resultCode, errorMsg)
            }
        }

        return (false, -2, "Could not parse result code from response")
    }

    /// Human-readable LDAP result code descriptions
    private func ldapResultCodeDescription(_ code: Int) -> String {
        switch code {
        case 0: return "success"
        case 1: return "operationsError"
        case 2: return "protocolError"
        case 3: return "timeLimitExceeded"
        case 4: return "sizeLimitExceeded"
        case 7: return "authMethodNotSupported"
        case 8: return "strongerAuthRequired"
        case 14: return "saslBindInProgress"
        case 16: return "noSuchAttribute"
        case 32: return "noSuchObject"
        case 34: return "invalidDNSyntax"
        case 48: return "inappropriateAuthentication"
        case 49: return "invalidCredentials"
        case 50: return "insufficientAccessRights"
        case 51: return "busy"
        case 52: return "unavailable"
        case 53: return "unwillingToPerform"
        case 80: return "other"
        default: return "unknownError(\(code))"
        }
    }
}
