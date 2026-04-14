// MARK: - MoodLevel
// Рівень настрою для запису щоденника.
import Foundation
import SwiftUI

enum MoodLevel: Int, Codable, CaseIterable, Identifiable {
    case awful = 1, bad, neutral, good, excellent

    var id: Int { rawValue }

    var emoji: String {
        ["😢", "😔", "😐", "😊", "😄"][rawValue - 1]
    }

    var label: String {
        let en = ["Awful", "Bad", "Neutral", "Good", "Excellent"]
        let uk = ["Жахливо", "Погано", "Нейтрально", "Добре", "Чудово"]
        return LanguageManager.shared.l(en[rawValue - 1], uk[rawValue - 1])
    }

    // Hex string — використовується для передачі через UserDefaults у widget
    var color: String {
        ["#FF4B4B", "#FF8C42", "#FFD166", "#06D6A0", "#4ECDC4"][rawValue - 1]
    }

    // SwiftUI Color з Assets.xcassets — використовується в UI main app
    var swiftUIColor: Color {
        switch self {
        case .awful:    return .moodAwful
        case .bad:      return .moodBad
        case .neutral:  return .moodNeutral
        case .good:     return .moodGood
        case .excellent: return .moodExcellent
        }
    }
}
