// MARK: - Onboarding View
// Перший запуск: слайдер з фічами + кнопка "Почати".
import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void

    @EnvironmentObject private var theme: AppTheme
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "book.closed.fill",
            title: "Твій особистий\nщоденник",
            subtitle: "Записуй думки, відслідковуй настрій і відкривай паттерни у своєму житті",
            features: [
                ("lock.fill",        "Захист Face ID — тільки для тебе"),
                ("chart.bar.fill",   "Аналітика настрою та активності"),
                ("sparkles",         "AI-підказки для натхнення")
            ]
        ),
        OnboardingPage(
            icon: "face.smiling",
            title: "Відстежуй\nсвій настрій",
            subtitle: "Щодня фіксуй емоції та бач, як змінюється твій стан протягом тижнів і місяців",
            features: [
                ("calendar",         "Щоденний mood check-in"),
                ("flame.fill",       "Streaks тримають мотивацію"),
                ("bell.fill",        "Нагадування у зручний час")
            ]
        )
    ]

    var body: some View {
        ZStack {
            Color.diaryBackground.ignoresSafeArea()

            Circle()
                .fill(theme.accent.opacity(0.15))
                .frame(width: 350, height: 350)
                .blur(radius: 80)
                .offset(x: -60, y: -200)

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { idx in
                        OnboardingPageView(page: pages[idx])
                            .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)

                VStack(spacing: 20) {
                    HStack(spacing: 8) {
                        ForEach(pages.indices, id: \.self) { idx in
                            Capsule()
                                .fill(idx == currentPage ? theme.accent : Color.diaryTertiary)
                                .frame(width: idx == currentPage ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }

                    Button(action: {
                        if currentPage < pages.count - 1 {
                            withAnimation { currentPage += 1 }
                        } else {
                            onFinish()
                        }
                    }) {
                        Text(currentPage < pages.count - 1 ? "Далі" : "Почати ✨")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(theme.accent)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 24)

                    Button(action: onFinish) {
                        Text("Вже є акаунт? Увійти")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.diarySecondary)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Page Model
struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
    let features: [(String, String)]
}

// MARK: - Page View
struct OnboardingPageView: View {
    let page: OnboardingPage

    @EnvironmentObject private var theme: AppTheme

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.diarySurface)
                    .frame(width: 96, height: 96)
                Image(systemName: page.icon)
                    .font(.system(size: 44))
                    .foregroundStyle(theme.accent)
            }

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Color.diaryPrimaryText)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.diarySecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 12) {
                ForEach(page.features, id: \.1) { feature in
                    HStack(spacing: 12) {
                        Image(systemName: feature.0)
                            .font(.system(size: 16))
                            .foregroundStyle(theme.accent)
                            .frame(width: 24)
                        Text(feature.1)
                            .font(.system(size: 15))
                            .foregroundStyle(Color.diarySecondary)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.diaryCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }
}

#Preview {
    OnboardingView(onFinish: {})
        .environmentObject(AppTheme())
}
