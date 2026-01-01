import Foundation

// MARK: - EWS Credentials

/// Credentials for Exchange Web Services authentication
struct EWSCredentials: Codable {
    let serverURL: String      // e.g., "https://exchange.company.ru"
    let domain: String         // e.g., "COMPANY"
    let username: String       // e.g., "user" (without domain prefix)
    let password: String       // stored encrypted in Keychain
    var email: String?         // discovered or user-entered

    /// Full username in DOMAIN\user format for NTLM
    var ntlmUsername: String {
        return "\(domain)\\\(username)"
    }

    /// Full EWS endpoint URL
    var ewsEndpoint: URL? {
        let baseURL = serverURL.hasSuffix("/") ? String(serverURL.dropLast()) : serverURL
        return URL(string: baseURL + IntegrationConfig.EWS.endpointPath)
    }
}

// MARK: - EWS Calendar Event

/// Represents a calendar event from Exchange
struct EWSEvent: Identifiable {
    let itemId: String
    let changeKey: String       // Required for UpdateItem operations
    let subject: String
    let startDate: Date
    let endDate: Date
    let location: String?
    let bodyHtml: String?
    let bodyText: String?
    let attendees: [EWSAttendee]
    let organizerEmail: String?
    let organizerName: String?
    let isAllDay: Bool

    var id: String { itemId }

    /// Duration in minutes
    var durationMinutes: Int {
        Int(endDate.timeIntervalSince(startDate) / 60)
    }
}

// MARK: - EWS Attendee

/// Represents a meeting attendee
struct EWSAttendee: Identifiable, Hashable {
    let email: String
    let name: String?
    let responseType: EWSResponseType
    let isRequired: Bool

    var id: String { email }

    var displayName: String {
        name ?? email
    }
}

/// Attendee response status
enum EWSResponseType: String, Codable {
    case unknown = "Unknown"
    case organizer = "Organizer"
    case tentative = "Tentative"
    case accept = "Accept"
    case decline = "Decline"
    case noResponseReceived = "NoResponseReceived"

    var displayText: String {
        switch self {
        case .unknown: return "Неизвестно"
        case .organizer: return "Организатор"
        case .tentative: return "Под вопросом"
        case .accept: return "Принял"
        case .decline: return "Отклонил"
        case .noResponseReceived: return "Нет ответа"
        }
    }

    var iconName: String {
        switch self {
        case .unknown: return "questionmark.circle"
        case .organizer: return "person.circle.fill"
        case .tentative: return "questionmark.circle.fill"
        case .accept: return "checkmark.circle.fill"
        case .decline: return "xmark.circle.fill"
        case .noResponseReceived: return "clock.fill"
        }
    }
}

// MARK: - EWS Contact

/// Contact from ResolveNames operation (for autocomplete)
struct EWSContact: Identifiable {
    let email: String
    let displayName: String
    let mailboxType: EWSMailboxType
    let department: String?
    let jobTitle: String?

    var id: String { email }
}

/// Mailbox type from Exchange
enum EWSMailboxType: String, Codable {
    case mailbox = "Mailbox"
    case publicDL = "PublicDL"
    case privateD = "PrivateDL"
    case contact = "Contact"
    case publicFolder = "PublicFolder"
    case unknown = "Unknown"

    var isDistributionList: Bool {
        self == .publicDL || self == .privateD
    }
}

// MARK: - EWS New Event

/// Data for creating a new calendar event
struct EWSNewEvent {
    let subject: String
    let bodyHtml: String?
    let startDate: Date
    let endDate: Date
    let location: String?
    let requiredAttendees: [String] // emails
    let optionalAttendees: [String] // emails
    let isAllDay: Bool

    init(
        subject: String,
        bodyHtml: String? = nil,
        startDate: Date,
        endDate: Date,
        location: String? = nil,
        requiredAttendees: [String] = [],
        optionalAttendees: [String] = [],
        isAllDay: Bool = false
    ) {
        self.subject = subject
        self.bodyHtml = bodyHtml
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.requiredAttendees = requiredAttendees
        self.optionalAttendees = optionalAttendees
        self.isAllDay = isAllDay
    }
}

// MARK: - EWS New Email

/// Data for sending an email
struct EWSNewEmail {
    let toRecipients: [String]  // emails
    let ccRecipients: [String]  // emails
    let subject: String
    let bodyHtml: String
    let saveToSentItems: Bool

    init(
        toRecipients: [String],
        ccRecipients: [String] = [],
        subject: String,
        bodyHtml: String,
        saveToSentItems: Bool = true
    ) {
        self.toRecipients = toRecipients
        self.ccRecipients = ccRecipients
        self.subject = subject
        self.bodyHtml = bodyHtml
        self.saveToSentItems = saveToSentItems
    }
}

// MARK: - EWS Errors

/// Errors that can occur during EWS operations
enum EWSError: LocalizedError {
    case notConfigured
    case invalidServerURL
    case authenticationFailed
    case serverError(String)
    case parseError(String)
    case networkError(Error)
    case itemNotFound
    case changeKeyMismatch
    case accessDenied
    case throttled
    case soapFault(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Exchange сервер не настроен"
        case .invalidServerURL:
            return "Неверный URL сервера Exchange"
        case .authenticationFailed:
            return "Ошибка аутентификации. Проверьте логин и пароль."
        case .serverError(let message):
            return "Ошибка сервера: \(message)"
        case .parseError(let detail):
            return "Ошибка разбора ответа: \(detail)"
        case .networkError(let error):
            return "Сетевая ошибка: \(error.localizedDescription)"
        case .itemNotFound:
            return "Элемент не найден"
        case .changeKeyMismatch:
            return "Элемент был изменён. Обновите данные и попробуйте снова."
        case .accessDenied:
            return "Доступ запрещён"
        case .throttled:
            return "Превышен лимит запросов. Попробуйте позже."
        case .soapFault(let fault):
            return "Ошибка Exchange: \(fault)"
        }
    }
}
