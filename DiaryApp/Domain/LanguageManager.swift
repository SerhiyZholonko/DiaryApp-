// MARK: - Language Manager
// Зберігає вибрану мову інтерфейсу та надає хелпер l(_:_:) для локалізації.
import Foundation
import Combine

enum AppLanguage: String, CaseIterable {
    case english   = "en"
    case ukrainian = "uk"

    var displayName: String {
        switch self {
        case .english:   return "English"
        case .ukrainian: return "Українська"
        }
    }

    var localeIdentifier: String {
        switch self {
        case .english:   return "en_US"
        case .ukrainian: return "uk_UA"
        }
    }
}

final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "app_language") }
    }

    private init() {
        let raw = UserDefaults.standard.string(forKey: "app_language") ?? "en"
        language = AppLanguage(rawValue: raw) ?? .english
    }

    /// Returns `en` when English is active, `uk` when Ukrainian.
    func l(_ en: String, _ uk: String) -> String {
        language == .english ? en : uk
    }

    var locale: Locale { Locale(identifier: language.localeIdentifier) }
    var isUkrainian: Bool { language == .ukrainian }
}
