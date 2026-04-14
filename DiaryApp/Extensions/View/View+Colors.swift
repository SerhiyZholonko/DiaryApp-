// MARK: - Diary Design System Colors
// diaryBackground, diaryCard, diarySurface, diaryDivider,
// diaryPrimaryText, diarySecondary, diaryTertiary —
// генеруються автоматично з Assets.xcassets (GeneratedAssetSymbols.swift)
import SwiftUI

// Всі кольори з Assets.xcassets (MoodAwful, MoodBad, MoodNeutral, MoodGood, MoodExcellent,
// StreakFlameHigh, StreakFlameExtreme, DiaryPurple, DiaryBlue, DiaryVideoGreen, GoogleBlue
// та інші) генеруються автоматично в GeneratedAssetSymbols.swift як Color.moodAwful і т.д.

// MARK: - Hex Color Init
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >>  8) & 0xFF) / 255
            b = Double( int        & 0xFF) / 255
            a = 1
        case 8:
            r = Double((int >> 24) & 0xFF) / 255
            g = Double((int >> 16) & 0xFF) / 255
            b = Double((int >>  8) & 0xFF) / 255
            a = Double( int        & 0xFF) / 255
        default:
            r = 0; g = 0; b = 0; a = 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
