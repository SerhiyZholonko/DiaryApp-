// MARK: - App Starting View
// Роутер: Onboarding → Auth → Main залежно від AppState.
import SwiftUI

struct AppStartingView: View {
    @StateObject private var viewModel = AppStartingViewModel()

    var body: some View {
        Group {
            switch viewModel.appState {
            case .onboarding:
                OnboardingView(onFinish: viewModel.completeOnboarding)
            case .auth:
                AuthView(onSignedIn: viewModel.userDidSignIn)
            case .main:
                MainTabView(onSignOut: viewModel.userDidSignOut)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.appState)
    }
}

#Preview { AppStartingView() }
