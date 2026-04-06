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
        Task {
            defer { isLoading = false }
            do {
                let user = try await authStore.signInWithGoogle(presenting: rootVC)
                onSignedIn?(user)
            } catch {
                self.error = error
            }
        }
    }

    func signInWithApple() {
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                let user = try await authStore.signInWithApple()
                onSignedIn?(user)
            } catch {
                // Code=1001 — користувач сам закрив діалог, не показуємо помилку
                let nsError = error as NSError
                guard nsError.code != 1001 else { return }
                self.error = error
            }
        }
    }
}
