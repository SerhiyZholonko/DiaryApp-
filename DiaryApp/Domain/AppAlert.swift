// MARK: - App Alert
// Модель алерту для AlertDisplayable + .showAlert() модифікатора.
import Foundation

struct AppAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String?
    let actionTitle: String
    let action: () -> Void

    init(title: String, message: String? = nil, actionTitle: String = "OK", action: @escaping () -> Void = {}) {
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
}
