// MARK: - Diary List View
// Головний екран: список записів + відображення настрою.
import SwiftUI

struct DiaryListView: View {
    let onNewEntry: () -> Void
    let onEdit: (DiaryEntry) -> Void
    let namespace: Namespace.ID

    @EnvironmentObject private var theme: AppTheme
    @EnvironmentObject private var lang: LanguageManager
    @StateObject private var viewModel = DiaryListViewModel()
    @AppStorage("ai_insights_enabled") private var aiInsightsEnabled = true
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.diaryBackground.ignoresSafeArea()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: []) {
                    // Header
                    headerView
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 8)

                    // Month label
                    if let firstGroup = viewModel.groupedEntries.first {
                        Text(firstGroup.key)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.diarySecondary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 4)
                    }

                    // Mood display (read-only)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(lang.l("Today's Mood", "Настрій сьогодні"))
                            .font(.system(size: 13))
                            .foregroundStyle(Color.diarySecondary)
                            .padding(.horizontal, 20)

                        HStack(spacing: 0) {
                            ForEach(MoodLevel.allCases) { mood in
                                ZStack {
                                    if viewModel.todayMood == mood {
                                        Circle()
                                            .fill(theme.accent.opacity(0.25))
                                            .frame(width: 52, height: 52)
                                    }
                                    Text(mood.emoji)
                                        .font(.system(size: 30))
                                        .scaleEffect(viewModel.todayMood == mood ? 1.15 : 1.0)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                    .padding(.vertical, 12)

                    // Divider
                    Rectangle()
                        .fill(Color.diaryDivider)
                        .frame(height: 1)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)

                    // AI Insights Card
                    if aiInsightsEnabled {
                        AIInsightsCard()
                            .padding(.horizontal, 20)
                            .padding(.bottom, 12)
                    }

                    // Entries
                    if viewModel.isLoading {
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.diaryCard)
                                .frame(height: 120)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 12)
                                .redacted(reason: .placeholder)
                        }
                    } else if viewModel.entries.isEmpty {
                        emptyState
                    } else {
                        ForEach(viewModel.groupedEntries, id: \.key) { group in
                            if group.key != viewModel.groupedEntries.first?.key {
                                Text(group.key)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.diarySecondary)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 8)
                                    .padding(.bottom, 4)
                            }
                            ForEach(group.entries) { entry in
                                DiaryEntryCard(
                                    entry: entry,
                                    onEdit: { onEdit(entry) },
                                    onDelete: { viewModel.delete(entry) }
                                )
                                .matchedGeometryEffect(id: entry.id, in: namespace)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 12)
                                .onTapGesture { onEdit(entry) }
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .opacity.combined(with: .scale(scale: 0.95))
                                ))
                            }
                        }
                    }

                    Spacer().frame(height: 90)
                }
            }
        }
        .showError(viewModel: viewModel)
        .onAppear {
            viewModel.load()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) { appeared = true }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.entries.count)
    }

    // MARK: - Header
    private var headerView: some View {
        HStack(alignment: .center) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(
                            colors: [theme.accent.opacity(0.35), theme.accent.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 36, height: 36)
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(theme.accent)
                }
                Text(lang.l("My Diary", "Мій Щоденник"))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.diaryPrimaryText)
            }
            Spacer()
            if viewModel.currentStreak > 0 {
                StreakBadge(streak: viewModel.currentStreak)
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("📖")
                .font(.system(size: 48))
            Text(lang.l("No entries yet", "Записів немає"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.diaryPrimaryText)
            Text(lang.l("Tap + to create your first entry", "Натисни + щоб створити перший запис"))
                .font(.system(size: 14))
                .foregroundStyle(Color.diarySecondary)
            Button(action: onNewEntry) {
                Text(lang.l("Create Entry", "Створити запис"))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(theme.accent)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}

// MARK: - Streak Badge
struct StreakBadge: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 4) {
            Text("🔥")
            Text("\(streak) \(dayLabel(streak))")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.diaryPrimaryText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            LinearGradient(
                colors: [Color(hex: "#FF6B35").opacity(0.18), Color.diaryCard],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(Capsule())
    }

    private func dayLabel(_ count: Int) -> String {
        LanguageManager.shared.l(count == 1 ? "day" : "days",
                                  count == 1 ? "день" : "днів")
    }
}

#Preview {
    @Previewable @Namespace var ns
    DiaryListView(onNewEntry: {}, onEdit: { _ in }, namespace: ns)
        .environmentObject(AppTheme())
        .preferredColorScheme(.dark)
}
