// MARK: - DiaryEntry Model
// Основна доменна модель запису щоденника.
// Codable для Firebase/UserDefaults, Identifiable для SwiftUI списків.
import Foundation

struct DiaryEntry: Identifiable, Codable {
    let id: String
    var text: String
    var mood: MoodLevel?
    var tags: [String]
    var attachments: [MediaAttachment]
    var createdAt: Date
    var updatedAt: Date

    var wordCount: Int {
        guard !text.isEmpty else { return 0 }
        return text.split { $0.isWhitespace || $0.isNewline }.count
    }

    var preview: String {
        let plain = text
            .replacingOccurrences(of: #"\*\*(.+?)\*\*"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"\*(.+?)\*"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"^#{1,6}\s"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"^[-*]\s"#, with: "", options: .regularExpression)
        return String(plain.prefix(120))
    }

    init(
        id: String = UUID().uuidString,
        text: String = "",
        mood: MoodLevel? = nil,
        tags: [String] = [],
        attachments: [MediaAttachment] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.text = text
        self.mood = mood
        self.tags = tags
        self.attachments = attachments
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
