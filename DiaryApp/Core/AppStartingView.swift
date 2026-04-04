// MARK: - App Starting View
// Роутер: Onboarding → Auth → Main залежно від AppState.
// Показує LockScreenView поверх Main, якщо Face ID увімкнено.
import SwiftUI

struct AppStartingView: View {
    @StateObject private var viewModel = AppStartingViewModel()
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.scenePhase) private var scenePhase

    @State private var isLocked = false
    @State private var isAuthenticating = false

    var body: some View {
        Group {
            switch viewModel.appState {
            case .onboarding:
                OnboardingView(onFinish: viewModel.completeOnboarding)
            case .auth:
                AuthView(onSignedIn: viewModel.userDidSignIn)
            case .main:
                MainTabView(onSignOut: viewModel.userDidSignOut)
                    .overlay {
                        if isLocked {
                            LockScreenView(onUnlock: unlock)
                                .transition(.opacity)
                        }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.appState)
        .onChange(of: viewModel.appState) { _, newState in
            if newState == .main && SecurityStore.shared.isEnabled {
                isLocked = true
                unlock()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard viewModel.appState == .main else { return }
            if newPhase == .background && SecurityStore.shared.isEnabled {
                isLocked = true
            } else if newPhase == .active && isLocked {
                unlock()
            }
        }
    }

    private func unlock() {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        Task { @MainActor in
            defer { isAuthenticating = false }
            let ok = (try? await SecurityStore.shared.authenticate()) ?? false
            if ok { withAnimation { isLocked = false } }
        }
    }
}

// MARK: - Lock Screen

struct LockScreenView: View {
    let onUnlock: () -> Void

    @EnvironmentObject private var theme: AppTheme

    var body: some View {
        ZStack {
            Color.diaryBackground.ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(theme.accent)
                Text("Щоденник заблоковано")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.diaryPrimaryText)
                Button(action: onUnlock) {
                    Label("Розблокувати", systemImage: "faceid")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(theme.accent)
                        .clipShape(Capsule())
                }
            }
        }
    }
}

#Preview { AppStartingView() }
