// MARK: - App State
// Стан навігації. AppStartingViewModel змінює → AppStartingView відображає.
import Foundation

enum AppState {
    case onboarding  // Перший запуск
    case auth        // Неавторизований
    case main        // Авторизований
}
