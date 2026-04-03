// MARK: - View Color Extensions
// Semantic colors + Diary App design system colors.
import SwiftUI
import UIKit

// MARK: - Semantic Colors (xcassets)
extension Color {
    static let textColor               = Color("TextColor")
    static let secondaryTextColor      = Color("SecondaryTextColor")
    static let accentContrastTextColor = Color("AccentContrastTextColor")
    static let alternateTextColor      = Color("AlternateTextColor")
    static let viewBackgroundColor     = Color("ViewBackgroundColor")
    static let cellBackgroundColor     = Color("CellBackgroundColor")
    static let primaryActionColor      = Color("PrimaryActionColor")
    static let neutralActionColor      = Color("NeutralActionColor")
    static let destructiveColor        = Color("DestructiveColor")
    static let alternateAccentColor    = Color("AlternateAccentColor")
    static let successColor            = Color("SuccessColor")
    static let errorColor              = Color("ErrorColor")
    static let warningColor            = Color("WarningColor")
    static let inProgressColor         = Color("InProgressColor")
    static let infoColor               = Color("InfoColor")
    static let miscellaneousColor      = Color("MiscellaneousColor")
    static let dividerColor            = Color("DividerColor")
}

// MARK: - Diary Design System Colors (adaptive Light/Dark)
extension Color {
    /// Фон додатку — адаптивний: темний #0D0D1A / світлий #F2F2F7
    static let diaryBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0x0D/255, green: 0x0D/255, blue: 0x1A/255, alpha: 1)
            : UIColor(red: 0xF2/255, green: 0xF2/255, blue: 0xF7/255, alpha: 1)
    })
    /// Фон карток — адаптивний: #1A1A2E / #FFFFFF
    static let diaryCard = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0x1A/255, green: 0x1A/255, blue: 0x2E/255, alpha: 1)
            : UIColor.white
    })
    /// Фон другорядних елементів — адаптивний: #13132B / #F2F2F7
    static let diarySurface = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0x13/255, green: 0x13/255, blue: 0x2B/255, alpha: 1)
            : UIColor(red: 0xF2/255, green: 0xF2/255, blue: 0xF7/255, alpha: 1)
    })
    /// Основний акцент — фіолетовий #7B61FF (однаковий в обох темах)
    static let diaryPurple      = Color(hex: "#7B61FF")
    /// Світліший фіолетовий #9B85FF
    static let diaryPurpleLight = Color(hex: "#9B85FF")
    /// Розділювач — адаптивний: white 10% / #E5E5EA
    static let diaryDivider = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.1)
            : UIColor(red: 0xE5/255, green: 0xE5/255, blue: 0xEA/255, alpha: 1)
    })
    /// Другорядний текст — адаптивний: white 50% / #8E8E93
    static let diarySecondary = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.5)
            : UIColor(red: 0x8E/255, green: 0x8E/255, blue: 0x93/255, alpha: 1)
    })
    /// Третинний текст — адаптивний: white 30% / #C7C7CC
    static let diaryTertiary = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.3)
            : UIColor(red: 0xC7/255, green: 0xC7/255, blue: 0xCC/255, alpha: 1)
    })
    /// Основний текст — white у темній / #0D0D1A у світлій темі
    static let diaryPrimaryText = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.white
            : UIColor(red: 0x0D/255, green: 0x0D/255, blue: 0x1A/255, alpha: 1)
    })
}

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

// MARK: - Text Color Helpers
extension View {
    func textColor()               -> some View { foregroundStyle(Color.textColor) }
    func secondaryTextColor()      -> some View { foregroundStyle(Color.secondaryTextColor) }
    func accentContrastTextColor() -> some View { foregroundStyle(Color.accentContrastTextColor) }
    func alternateTextColor()      -> some View { foregroundStyle(Color.alternateTextColor) }
}
