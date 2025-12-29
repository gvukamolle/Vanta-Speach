import Foundation

/// Configuration for third-party integrations
/// Replace placeholder values before production use
enum IntegrationConfig {

    // MARK: - Google Docs & Drive

    enum Google {
        /// Google Cloud Console Client ID
        /// Create at: https://console.cloud.google.com/apis/credentials
        /// Application type: iOS
        static let clientID = "YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com"

        /// Reversed client ID for URL scheme (auto-generated)
        static var reversedClientID: String {
            let parts = clientID.components(separatedBy: ".")
            return parts.reversed().joined(separator: ".")
        }

        /// OAuth scopes for Google APIs
        static let scopes = [
            "https://www.googleapis.com/auth/drive.file",    // Create/access files created by app
            "https://www.googleapis.com/auth/documents"       // Read/write Google Docs
        ]

        /// Google Docs API base URL
        static let docsAPIBaseURL = "https://docs.googleapis.com/v1"

        /// Google Drive API base URL
        static let driveAPIBaseURL = "https://www.googleapis.com/drive/v3"
    }

    // MARK: - Exchange Web Services (On-Premises)

    enum EWS {
        /// Exchange Server version for SOAP RequestServerVersion
        /// Supported: Exchange2010, Exchange2013, Exchange2016, Exchange2019
        static let exchangeVersion = "Exchange2019"

        /// Default EWS endpoint path (appended to server URL)
        static let endpointPath = "/EWS/Exchange.asmx"

        /// Request timeout in seconds
        static let requestTimeout: TimeInterval = 30

        /// Maximum concurrent requests (EWS throttling default is 27)
        static let maxConcurrentRequests = 10

        /// SOAP namespaces
        enum Namespace {
            static let soap = "http://schemas.xmlsoap.org/soap/envelope/"
            static let types = "http://schemas.microsoft.com/exchange/services/2006/types"
            static let messages = "http://schemas.microsoft.com/exchange/services/2006/messages"
        }
    }
}
