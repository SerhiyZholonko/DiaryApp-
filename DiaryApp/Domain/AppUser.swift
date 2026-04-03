// MARK: - App User
// Модель авторизованого користувача (зберігається в AppSession).
import Foundation

struct AppUser {
    let id: String
    var displayName: String?
    var email: String?
    var photoURL: URL?
}
