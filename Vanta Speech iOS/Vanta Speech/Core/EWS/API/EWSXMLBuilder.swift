import Foundation

/// Builds SOAP XML envelopes for Exchange Web Services requests
enum EWSXMLBuilder {

    // MARK: - SOAP Envelope Wrapper

    /// Wraps body content in a SOAP envelope with EWS namespaces
    static func wrapInEnvelope(_ body: String) -> String {
        """
        <?xml version="1.0" encoding="utf-8"?>
        <soap:Envelope xmlns:soap="\(IntegrationConfig.EWS.Namespace.soap)"
                       xmlns:t="\(IntegrationConfig.EWS.Namespace.types)"
                       xmlns:m="\(IntegrationConfig.EWS.Namespace.messages)">
          <soap:Header>
            <t:RequestServerVersion Version="\(IntegrationConfig.EWS.exchangeVersion)"/>
          </soap:Header>
          <soap:Body>
            \(body)
          </soap:Body>
        </soap:Envelope>
        """
    }

    // MARK: - FindItem (Calendar Events)

    /// Build FindItem request for calendar events in a date range
    static func buildFindItemRequest(
        startDate: Date,
        endDate: Date,
        maxEntries: Int = 100
    ) -> String {
        let start = formatISO8601(startDate)
        let end = formatISO8601(endDate)

        let body = """
        <m:FindItem Traversal="Shallow">
          <m:ItemShape>
            <t:BaseShape>Default</t:BaseShape>
            <t:AdditionalProperties>
              <t:FieldURI FieldURI="calendar:Start"/>
              <t:FieldURI FieldURI="calendar:End"/>
              <t:FieldURI FieldURI="calendar:Location"/>
              <t:FieldURI FieldURI="calendar:Organizer"/>
              <t:FieldURI FieldURI="calendar:RequiredAttendees"/>
              <t:FieldURI FieldURI="calendar:OptionalAttendees"/>
              <t:FieldURI FieldURI="calendar:IsAllDayEvent"/>
              <t:FieldURI FieldURI="item:Subject"/>
              <t:FieldURI FieldURI="item:Body"/>
            </t:AdditionalProperties>
          </m:ItemShape>
          <m:CalendarView MaxEntriesReturned="\(maxEntries)" StartDate="\(start)" EndDate="\(end)"/>
          <m:ParentFolderIds>
            <t:DistinguishedFolderId Id="calendar"/>
          </m:ParentFolderIds>
        </m:FindItem>
        """
        return wrapInEnvelope(body)
    }

    // MARK: - GetItem (Event Details)

    /// Build GetItem request for detailed event info including attendees
    static func buildGetItemRequest(itemId: String, changeKey: String) -> String {
        let body = """
        <m:GetItem>
          <m:ItemShape>
            <t:BaseShape>AllProperties</t:BaseShape>
            <t:AdditionalProperties>
              <t:FieldURI FieldURI="calendar:RequiredAttendees"/>
              <t:FieldURI FieldURI="calendar:OptionalAttendees"/>
              <t:FieldURI FieldURI="calendar:Resources"/>
              <t:FieldURI FieldURI="item:Body"/>
            </t:AdditionalProperties>
          </m:ItemShape>
          <m:ItemIds>
            <t:ItemId Id="\(escapeXML(itemId))" ChangeKey="\(escapeXML(changeKey))"/>
          </m:ItemIds>
        </m:GetItem>
        """
        return wrapInEnvelope(body)
    }

    // MARK: - UpdateItem (Update Event Body)

    /// Build UpdateItem request to update event body (append summary)
    static func buildUpdateItemBodyRequest(
        itemId: String,
        changeKey: String,
        bodyHtml: String,
        notifyAttendees: Bool = false
    ) -> String {
        let sendInvites = notifyAttendees ? "SendToAllAndSaveCopy" : "SendToNone"
        let escapedBody = escapeXML(bodyHtml)

        let body = """
        <m:UpdateItem ConflictResolution="AlwaysOverwrite" SendMeetingInvitationsOrCancellations="\(sendInvites)">
          <m:ItemChanges>
            <t:ItemChange>
              <t:ItemId Id="\(escapeXML(itemId))" ChangeKey="\(escapeXML(changeKey))"/>
              <t:Updates>
                <t:SetItemField>
                  <t:FieldURI FieldURI="item:Body"/>
                  <t:CalendarItem>
                    <t:Body BodyType="HTML">\(escapedBody)</t:Body>
                  </t:CalendarItem>
                </t:SetItemField>
              </t:Updates>
            </t:ItemChange>
          </m:ItemChanges>
        </m:UpdateItem>
        """
        return wrapInEnvelope(body)
    }

    /// Build UpdateItem request to update event subject
    static func buildUpdateItemSubjectRequest(
        itemId: String,
        changeKey: String,
        subject: String,
        notifyAttendees: Bool = false
    ) -> String {
        let sendInvites = notifyAttendees ? "SendToAllAndSaveCopy" : "SendToNone"

        let body = """
        <m:UpdateItem ConflictResolution="AlwaysOverwrite" SendMeetingInvitationsOrCancellations="\(sendInvites)">
          <m:ItemChanges>
            <t:ItemChange>
              <t:ItemId Id="\(escapeXML(itemId))" ChangeKey="\(escapeXML(changeKey))"/>
              <t:Updates>
                <t:SetItemField>
                  <t:FieldURI FieldURI="item:Subject"/>
                  <t:CalendarItem>
                    <t:Subject>\(escapeXML(subject))</t:Subject>
                  </t:CalendarItem>
                </t:SetItemField>
              </t:Updates>
            </t:ItemChange>
          </m:ItemChanges>
        </m:UpdateItem>
        """
        return wrapInEnvelope(body)
    }

    // MARK: - CreateItem (New Calendar Event)

    /// Build CreateItem request for a new calendar event
    static func buildCreateCalendarItemRequest(_ event: EWSNewEvent) -> String {
        let start = formatISO8601(event.startDate)
        let end = formatISO8601(event.endDate)

        var attendeesXml = ""

        if !event.requiredAttendees.isEmpty {
            attendeesXml += "<t:RequiredAttendees>\n"
            for email in event.requiredAttendees {
                attendeesXml += """
                  <t:Attendee>
                    <t:Mailbox>
                      <t:EmailAddress>\(escapeXML(email))</t:EmailAddress>
                    </t:Mailbox>
                  </t:Attendee>

                """
            }
            attendeesXml += "</t:RequiredAttendees>\n"
        }

        if !event.optionalAttendees.isEmpty {
            attendeesXml += "<t:OptionalAttendees>\n"
            for email in event.optionalAttendees {
                attendeesXml += """
                  <t:Attendee>
                    <t:Mailbox>
                      <t:EmailAddress>\(escapeXML(email))</t:EmailAddress>
                    </t:Mailbox>
                  </t:Attendee>

                """
            }
            attendeesXml += "</t:OptionalAttendees>\n"
        }

        let locationXml = event.location.map { "<t:Location>\(escapeXML($0))</t:Location>" } ?? ""
        let bodyXml = event.bodyHtml.map { "<t:Body BodyType=\"HTML\">\(escapeXML($0))</t:Body>" } ?? ""

        let body = """
        <m:CreateItem SendMeetingInvitations="SendToAllAndSaveCopy">
          <m:SavedItemFolderId>
            <t:DistinguishedFolderId Id="calendar"/>
          </m:SavedItemFolderId>
          <m:Items>
            <t:CalendarItem>
              <t:Subject>\(escapeXML(event.subject))</t:Subject>
              \(bodyXml)
              <t:Start>\(start)</t:Start>
              <t:End>\(end)</t:End>
              \(locationXml)
              <t:IsAllDayEvent>\(event.isAllDay ? "true" : "false")</t:IsAllDayEvent>
              \(attendeesXml)
            </t:CalendarItem>
          </m:Items>
        </m:CreateItem>
        """
        return wrapInEnvelope(body)
    }

    // MARK: - CreateItem (Send Email)

    /// Build CreateItem request to send an email
    static func buildCreateMessageRequest(_ email: EWSNewEmail) -> String {
        let disposition = email.saveToSentItems ? "SendAndSaveCopy" : "SendOnly"

        var toRecipientsXml = "<t:ToRecipients>\n"
        for recipient in email.toRecipients {
            toRecipientsXml += """
              <t:Mailbox>
                <t:EmailAddress>\(escapeXML(recipient))</t:EmailAddress>
              </t:Mailbox>

            """
        }
        toRecipientsXml += "</t:ToRecipients>\n"

        var ccRecipientsXml = ""
        if !email.ccRecipients.isEmpty {
            ccRecipientsXml = "<t:CcRecipients>\n"
            for recipient in email.ccRecipients {
                ccRecipientsXml += """
                  <t:Mailbox>
                    <t:EmailAddress>\(escapeXML(recipient))</t:EmailAddress>
                  </t:Mailbox>

                """
            }
            ccRecipientsXml += "</t:CcRecipients>\n"
        }

        let body = """
        <m:CreateItem MessageDisposition="\(disposition)">
          <m:SavedItemFolderId>
            <t:DistinguishedFolderId Id="sentitems"/>
          </m:SavedItemFolderId>
          <m:Items>
            <t:Message>
              <t:Subject>\(escapeXML(email.subject))</t:Subject>
              <t:Body BodyType="HTML">\(escapeXML(email.bodyHtml))</t:Body>
              \(toRecipientsXml)
              \(ccRecipientsXml)
            </t:Message>
          </m:Items>
        </m:CreateItem>
        """
        return wrapInEnvelope(body)
    }

    // MARK: - ResolveNames (Contact Search)

    /// Build ResolveNames request for contact autocomplete
    static func buildResolveNamesRequest(
        query: String,
        searchScope: String = "ContactsActiveDirectory"
    ) -> String {
        let body = """
        <m:ResolveNames ReturnFullContactData="true" SearchScope="\(searchScope)">
          <m:UnresolvedEntry>\(escapeXML(query))</m:UnresolvedEntry>
        </m:ResolveNames>
        """
        return wrapInEnvelope(body)
    }

    // MARK: - Helpers

    /// Format date to ISO 8601 for EWS
    private static func formatISO8601(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }

    /// Escape special XML characters
    private static func escapeXML(_ string: String) -> String {
        var escaped = string
        escaped = escaped.replacingOccurrences(of: "&", with: "&amp;")
        escaped = escaped.replacingOccurrences(of: "<", with: "&lt;")
        escaped = escaped.replacingOccurrences(of: ">", with: "&gt;")
        escaped = escaped.replacingOccurrences(of: "\"", with: "&quot;")
        escaped = escaped.replacingOccurrences(of: "'", with: "&apos;")
        return escaped
    }
}

// MARK: - SOAP Actions

extension EWSXMLBuilder {
    enum SOAPAction {
        static let findItem = "http://schemas.microsoft.com/exchange/services/2006/messages/FindItem"
        static let getItem = "http://schemas.microsoft.com/exchange/services/2006/messages/GetItem"
        static let updateItem = "http://schemas.microsoft.com/exchange/services/2006/messages/UpdateItem"
        static let createItem = "http://schemas.microsoft.com/exchange/services/2006/messages/CreateItem"
        static let resolveNames = "http://schemas.microsoft.com/exchange/services/2006/messages/ResolveNames"
    }
}
