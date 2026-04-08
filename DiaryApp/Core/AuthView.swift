// MARK: - Auth View
// Екран входу через Google Sign-In. Дизайн: темна тема Figma.
import SwiftUI

struct AuthView: View {
    let onSignedIn: (AppUser) -> Void

    @EnvironmentObject private var theme: AppTheme
    @EnvironmentObject private var lang: LanguageManager
    @StateObject private var viewModel = AuthViewModel()
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.diaryBackground.ignoresSafeArea()

            // Background glows
            Circle()
                .fill(theme.accent.opacity(0.2))
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(x: -80, y: -250)

            Circle()
                .fill(theme.accentLight.opacity(0.1))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: 120, y: 200)

            VStack(spacing: 0) {
                Spacer()

                // Logo + title
                VStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(
                                LinearGradient(
                                    colors: [theme.accent, theme.accentLight],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .shadow(color: theme.accent.opacity(0.5), radius: 24, x: 0, y: 10)
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.white)
                    }

                    Text("Diary")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(theme.accentLight)

                    Text(lang.l("Your personal place for thoughts", "Особисте місце для думок"))
                        .font(.system(size: 15))
                        .foregroundStyle(Color.diarySecondary)
                }
                .offset(y: appeared ? 0 : 28)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.65, dampingFraction: 0.8).delay(0.05), value: appeared)

                Spacer()

                // Sign-in card
                VStack(spacing: 20) {
                    VStack(spacing: 6) {
                        Text(lang.l("Sign In", "Увійти"))
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color.diaryPrimaryText)
                        Text(lang.l("Choose a sign-in method", "Обери спосіб входу"))
                            .font(.system(size: 14))
                            .foregroundStyle(Color.diarySecondary)
                    }

                    // Google button
                    Button(action: viewModel.signInWithGoogle) {
                        HStack(spacing: 12) {
                            Text("G")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(Color(hex: "#4285F4"))
                                .frame(width: 24)
                            Text(lang.l("Continue with Google", "Продовжити з Google"))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: Color.white.opacity(0.15), radius: 12, x: 0, y: 4)
                    }
                    .buttonStyle(SpringButtonStyle())
                    .disabled(viewModel.isLoading)
                    .overlay {
                        if viewModel.isLoading {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.black.opacity(0.3))
                            ProgressView().tint(.white)
                        }
                    }

                    // Divider
                    HStack {
                        Rectangle().fill(Color.diaryDivider).frame(height: 1)
                        Text(lang.l("or", "або")).font(.system(size: 13)).foregroundStyle(Color.diarySecondary)
                        Rectangle().fill(Color.diaryDivider).frame(height: 1)
                    }

                    // Apple button
                    Button(action: viewModel.signInWithApple) {
                        HStack(spacing: 12) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 18))
                            Text(lang.l("Continue with Apple", "Продовжити з Apple"))
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: Color.white.opacity(0.15), radius: 12, x: 0, y: 4)
                    }
                    .buttonStyle(SpringButtonStyle())
                    .disabled(viewModel.isLoading)

                    Text(lang.l("By continuing, you agree to our Terms and Privacy Policy",
                                "Продовжуючи, ви погоджуєтесь з нашими умовами та політикою конфіденційності"))
                        .font(.system(size: 11))
                        .foregroundStyle(Color.diaryTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .background(Color.diaryCard)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: Color.black.opacity(0.3), radius: 32, x: 0, y: 16)
                .padding(.horizontal, 20)
                .offset(y: appeared ? 0 : 40)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.65, dampingFraction: 0.82).delay(0.15), value: appeared)

                Spacer().frame(height: 40)
            }
        }
        .preferredColorScheme(.dark)
        .showError(viewModel: viewModel)
        .onAppear {
            viewModel.onSignedIn = onSignedIn
            appeared = true
        }
    }
}

#Preview {
    AuthView(onSignedIn: { _ in })
        .environmentObject(AppTheme())
}
