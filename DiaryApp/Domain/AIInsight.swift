// MARK: - AI Insight Model
import Foundation

struct AIInsight: Codable, Identifiable {
    let id: String
    var question: String   // Персоналізоване запитання для роздумів
    var pattern: String    // Виявлений емоційний паттерн
    var generatedAt: Date

    init(question: String, pattern: String) {
        self.id          = UUID().uuidString
        self.question    = question
        self.pattern     = pattern
        self.generatedAt = .now
    }
}
