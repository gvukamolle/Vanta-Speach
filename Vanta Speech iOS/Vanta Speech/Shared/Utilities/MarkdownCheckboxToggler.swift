import Foundation

/// Utility for toggling markdown checkboxes in text
struct MarkdownCheckboxToggler {

    /// Toggle a checkbox at the given line index
    /// - Parameters:
    ///   - text: The markdown text containing checkboxes
    ///   - lineIndex: The line number (0-indexed) to toggle
    /// - Returns: The updated markdown text with toggled checkbox
    static func toggleCheckbox(in text: String, at lineIndex: Int) -> String {
        var lines = text.components(separatedBy: "\n")
        guard lineIndex >= 0 && lineIndex < lines.count else { return text }

        let line = lines[lineIndex]

        // Toggle unchecked -> checked
        if line.contains("- [ ] ") {
            lines[lineIndex] = line.replacingOccurrences(of: "- [ ] ", with: "- [x] ")
        }
        // Toggle checked -> unchecked (both lowercase and uppercase x)
        else if line.contains("- [x] ") {
            lines[lineIndex] = line.replacingOccurrences(of: "- [x] ", with: "- [ ] ")
        }
        else if line.contains("- [X] ") {
            lines[lineIndex] = line.replacingOccurrences(of: "- [X] ", with: "- [ ] ")
        }

        return lines.joined(separator: "\n")
    }

    /// Find all checkbox lines in markdown text
    /// - Parameter text: The markdown text to search
    /// - Returns: Array of tuples with (lineIndex, isChecked, taskText)
    static func findCheckboxLines(in text: String) -> [(index: Int, isChecked: Bool, text: String)] {
        let lines = text.components(separatedBy: "\n")
        var result: [(Int, Bool, String)] = []

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("- [ ] ") {
                let taskText = String(trimmed.dropFirst(6))
                result.append((index, false, taskText))
            }
            else if trimmed.hasPrefix("- [x] ") || trimmed.hasPrefix("- [X] ") {
                let taskText = String(trimmed.dropFirst(6))
                result.append((index, true, taskText))
            }
        }

        return result
    }

    /// Check if a line is a checkbox line
    /// - Parameter line: The line to check
    /// - Returns: Tuple of (isCheckbox, isChecked) or nil if not a checkbox
    static func parseCheckboxLine(_ line: String) -> (isChecked: Bool, text: String)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        if trimmed.hasPrefix("- [ ] ") {
            return (false, String(trimmed.dropFirst(6)))
        }
        else if trimmed.hasPrefix("- [x] ") || trimmed.hasPrefix("- [X] ") {
            return (true, String(trimmed.dropFirst(6)))
        }

        return nil
    }
}
