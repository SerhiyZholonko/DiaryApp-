// MARK: - Auth ViewModel
// Google Sign-In через Firebase Auth.
import Foundation
import Combine
import Factory
import UIKit

@MainActor
final class AuthViewModel: ObservableObject, ErrorDisplayable, AlertDisplayable {
    @Published var isLoading = false
    @Published var error: Error?
    @Published var alert: AppAlert?

    @Injected(\.authStore) private var authStore: AuthStoreProtocol

    var onSignedIn: ((AppUser) -> Void)?

    func signInWithGoogle() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }
        isLoading = true
        Task(operation: {
            defer { isLoading = false }
            do {
                let user = try await authStore.signInWithGoogle(presenting: rootVC)
                onSignedIn?(user)
            } catch {
                self.error = error
            }
        })
    }
}
