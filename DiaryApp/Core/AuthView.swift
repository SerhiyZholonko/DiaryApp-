// MARK: - Auth View
// Екран входу через Google Sign-In. Дизайн: темна тема Figma.
import SwiftUI

struct AuthView: View {
    let onSignedIn: (AppUser) -> Void

    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        ZStack {
            Color.diaryBackground.ignoresSafeArea()

            // Background glows
            Circle()
                .fill(Color.diaryPurple.opacity(0.2))
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(x: -80, y: -250)

            Circle()
                .fill(Color.diaryPurpleLight.opacity(0.1))
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
                                    colors: [Color.diaryPurple, Color.diaryPurpleLight],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.white)
                    }

                    Text("Diary")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(Color.diaryPurpleLight)

                    Text("Твоє особисте місце для думок")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.diarySecondary)
                }

                Spacer()

                // Sign-in card
                VStack(spacing: 20) {
                    VStack(spacing: 6) {
                        Text("Увійти")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color.diaryPrimaryText)
                        Text("Обери зручний спосіб входу")
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
                            Text("Продовжити з Google")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
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
                        Text("або").font(.system(size: 13)).foregroundStyle(Color.diarySecondary)
                        Rectangle().fill(Color.diaryDivider).frame(height: 1)
                    }

                    // Apple button (disabled — coming soon)
                    Button(action: {}) {
                        HStack(spacing: 12) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 18))
                            Text("Продовжити з Apple")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(true)
                    .opacity(0.5)

                    Text("Продовжуючи, ти погоджуєшся з Умовами та Політикою конфіденційності")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.diaryTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .background(Color.diaryCard)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal, 20)

                Spacer().frame(height: 40)
            }
        }
        .preferredColorScheme(.dark)
        .showError(viewModel: viewModel)
        .onAppear {
            viewModel.onSignedIn = onSignedIn
        }
    }
}

#Preview {
    AuthView(onSignedIn: { _ in })
}
