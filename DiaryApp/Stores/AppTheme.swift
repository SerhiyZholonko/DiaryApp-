// MARK: - App Theme
// Зберігає поточний акцентний колір. Передається через environmentObject.
import SwiftUI
import Combine

final class AppTheme: ObservableObject {
    @Published var accentIdx: Int {
        didSet { UserDefaults.standard.set(accentIdx, forKey: "accent_color_idx") }
    }

    static let palette: [Color] = [
        Color("AccentViolet"),
        Color("AccentCyan"),
        Color("AccentRed"),
        Color("AccentGreen"),
        Color("AccentYellow")
    ]

    var accent:      Color { Self.palette[max(0, min(accentIdx, Self.palette.count - 1))] }
    var accentLight: Color { accent.opacity(0.7) }

    init() {
        self.accentIdx = UserDefaults.standard.integer(forKey: "accent_color_idx")
    }
}
