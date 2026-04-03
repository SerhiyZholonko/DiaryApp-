// MARK: - App Starting ViewModel
// Перевіряє сесію при старті → встановлює AppState.
import Foundation
import Combine
import Factory
import FirebaseAuth

@MainActor
final class AppStartingViewModel: ObservableObject {
    @Published var appState: AppState

    @Injected(\.authStore) private var authStore: AuthStoreProtocol

    init() {
        let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        if !hasSeenOnboarding {
            self.appState = .onboarding
        } else {
            // Initialize appState first, then check auth via container directly
            self.appState = .auth
        }
        // After all stored properties are initialized, check auth state
        if hasSeenOnboarding, let user = Container.shared.authStore().currentUser() {
            AppSession.shared.currentUser = user
            self.appState = .main
        }
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        appState = .auth
    }

    func userDidSignIn(_ user: AppUser) {
        AppSession.shared.currentUser = user
        appState = .main
    }

    func userDidSignOut() {
        AppSession.shared.currentUser = nil
        appState = .auth
    }
}
