// MARK: - App Session
// Singleton поточного сеансу. AppSession.shared.currentUser — з будь-якого місця.
import Foundation

final class AppSession {
    static let shared = AppSession()
    private init() {}
    var currentUser: AppUser?
    func clear() { currentUser = nil }
}
