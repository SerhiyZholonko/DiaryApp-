// MARK: - AuthStore Protocol
// Інтерфейс автентифікації.
import Foundation
import UIKit

protocol AuthStoreProtocol {
    func signInWithGoogle(presenting viewController: UIViewController) async throws -> AppUser
    func signOut() throws
    func currentUser() -> AppUser?
}
