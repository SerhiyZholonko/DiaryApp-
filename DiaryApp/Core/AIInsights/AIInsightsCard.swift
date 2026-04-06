// MARK: - AI Insights Card
// Компактна картка з AI-підказками у головному екрані щоденника.
import SwiftUI

struct AIInsightsCard: View {
    @EnvironmentObject private var theme: AppTheme
    @StateObject private var viewModel = AIInsightsViewModel()

    @State private var selectedTab: InsightTab = .question

    enum InsightTab: CaseIterable {
        case question, pattern
        var title: String {
            switch self {
            case .question: return "Запитання"
            case .pattern:  return "Паттерн"
            }
        }
        var icon: String {
            switch self {
            case .question: return "questionmark.bubble.fill"
            case .pattern:  return "chart.line.uptrend.xyaxis"
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            if viewModel.isConfigured {
                if viewModel.isLoading {
                    loadingView
                } else if let errorMessage = viewModel.errorMessage {
                    errorView(message: errorMessage)
                } else if let insight = viewModel.insight {
                    tabBar
                    insightContent(insight)
                } else {
                    emptyView
                }
            } else {
                notConfiguredView
            }
        }
        .background(Color.diaryCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear { viewModel.loadIfNeeded() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.accent)

            Text("AI-підказки")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.diaryPrimaryText)

            Spacer()

            if viewModel.isConfigured && !viewModel.isLoading {
                Button(action: { viewModel.refresh() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.diarySecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(InsightTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.18)) { selectedTab = tab }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 11, weight: .medium))
                        Text(tab.title)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(selectedTab == tab ? theme.accent : Color.diarySecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(
                        selectedTab == tab
                            ? theme.accent.opacity(0.12)
                            : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 6)
    }

    // MARK: - Insight Content

    private func insightContent(_ insight: AIInsight) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider().background(Color.diaryDivider)

            let text = selectedTab == .question ? insight.question : insight.pattern

            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(Color.diaryPrimaryText)
                .lineSpacing(3)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .id(selectedTab)

            HStack {
                Spacer()
                Text(insight.generatedAt, format: .relative(presentation: .named))
                    .font(.system(size: 10))
                    .foregroundStyle(Color.diaryTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
        }
    }

    // MARK: - States

    private var loadingView: some View {
        HStack(spacing: 8) {
            ProgressView().tint(theme.accent).scaleEffect(0.8)
            Text("Аналізую записи…")
                .font(.system(size: 13))
                .foregroundStyle(Color.diarySecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }

    private var emptyView: some View {
        Button(action: { viewModel.refresh() }) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                Text("Отримати підказки")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(theme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    private var notConfiguredView: some View {
        HStack(spacing: 8) {
            Image(systemName: "key.fill")
                .font(.system(size: 12))
                .foregroundStyle(Color.diarySecondary)
            Text("Додайте Gemini API ключ у Налаштуваннях")
                .font(.system(size: 12))
                .foregroundStyle(Color.diarySecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func errorView(message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "#FF4B4B"))
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 4) {
                Text(message)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.diarySecondary)
                Button(action: { viewModel.refresh() }) {
                    Text("Спробувати знову")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(theme.accent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

#Preview {
    AIInsightsCard()
        .environmentObject(AppTheme())
        .padding()
        .background(Color(hex: "#0D0D1A"))
        .preferredColorScheme(.dark)
}
