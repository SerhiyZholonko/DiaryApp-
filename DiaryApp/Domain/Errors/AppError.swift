// MARK: - App Error
// Кастомні помилки з LocalizedError описами.
import Foundation

enum AppError: LocalizedError {
    case unknown, networkError, unauthorized, invalidData

    var errorDescription: String? {
        let L: (String, String) -> String = LanguageManager.shared.l
        switch self {
        case .unknown:      return L("Unknown error. Please try again", "Невідома помилка. Спробуй знову")
        case .networkError: return L("Network error. Check your connection", "Помилка мережі. Перевір з'єднання")
        case .unauthorized: return L("Authorization required", "Потрібна авторизація")
        case .invalidData:  return L("Invalid or missing data", "Невірні або відсутні дані")
        }
    }
}
