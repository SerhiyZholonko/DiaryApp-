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

            VStack(spacing: 0) {
                // Sticky header
                headerView
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    .background(Color.diaryBackground)

                ScrollView {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: []) {
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
                    if viewModel.entries.isEmpty && !viewModel.isLoading {
                        emptyState
                    } else {
                        let allGroups = viewModel.groupedEntries
                        let lastEntry = allGroups.last?.entries.last
                        ForEach(allGroups, id: \.key) { group in
                            if group.key != allGroups.first?.key {
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
                                .onAppear {
                                    if entry.id == lastEntry?.id {
                                        viewModel.loadMore()
                                    }
                                }
                            }
                        }

                        if viewModel.isLoadingMore {
                            ProgressView()
                                .tint(theme.accent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                    }

                    Spacer().frame(height: 90)
                }
            }
            } // end outer VStack

            // Full-screen loading overlay
            if viewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.8)
                        .tint(theme.accent)
                    Text(lang.l("Loading...", "Завантаження..."))
                        .font(.system(size: 16))
                        .foregroundStyle(Color.diarySecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.diaryBackground.ignoresSafeArea())
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

    @EnvironmentObject private var lang: LanguageManager

    private var flameColor: Color {
        switch streak {
        case 1...2:   return .moodNeutral
        case 3...6:   return .moodBad
        case 7...13:  return .streakFlameHigh
        case 14...29: return .moodAwful
        default:      return .streakFlameExtreme
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.system(size: 17))
                .foregroundStyle(flameColor)
            Text("\(streak) \(dayLabel(streak))")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.diaryPrimaryText)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                colors: [flameColor.opacity(0.18), Color.diaryCard],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(Capsule())
    }

    private func dayLabel(_ count: Int) -> String {
        lang.l(count == 1 ? "day" : "days",
               count == 1 ? "день" : "днів")
    }
}

#Preview {
    @Previewable @Namespace var ns
    DiaryListView(onNewEntry: {}, onEdit: { _ in }, namespace: ns)
        .environmentObject(AppTheme())
        .preferredColorScheme(.dark)
}
