// MARK: - App Error
// Кастомні помилки з LocalizedError описами.
import Foundation

enum AppError: LocalizedError {
    case unknown, networkError, unauthorized, invalidData

    var errorDescription: String? {
        switch self {
        case .unknown:      return "Невідома помилка. Спробуйте ще раз"
        case .networkError: return "Помилка мережі. Перевірте підключення"
        case .unauthorized: return "Необхідна авторизація"
        case .invalidData:  return "Невірні або відсутні дані"
        }
    }
}
