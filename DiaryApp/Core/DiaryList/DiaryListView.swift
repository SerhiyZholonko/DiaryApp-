// MARK: - Diary List View
// Головний екран: список записів + вибір настрою.
import SwiftUI

struct DiaryListView: View {
    let onNewEntry: () -> Void

    @StateObject private var viewModel = DiaryListViewModel()
    @State private var entryToEdit: DiaryEntry?

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

                    // Mood picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Настрій сьогодні")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.diarySecondary)
                            .padding(.horizontal, 20)

                        MoodPickerView(selected: Binding(
                            get: { viewModel.todayMood },
                            set: { viewModel.setTodayMood($0 ?? .neutral) }
                        ))
                        .padding(.horizontal, 12)
                    }
                    .padding(.vertical, 12)

                    // Divider
                    Rectangle()
                        .fill(Color.diaryDivider)
                        .frame(height: 1)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)

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
                                    onEdit: { entryToEdit = entry },
                                    onDelete: { viewModel.delete(entry) }
                                )
                                .padding(.horizontal, 20)
                                .padding(.bottom, 12)
                                .onTapGesture { entryToEdit = entry }
                            }
                        }
                    }

                    Spacer().frame(height: 90) // tab bar padding
                }
            }
        }
        .sheet(item: $entryToEdit) { entry in
            EntryEditorView(entry: entry)
        }
        .showError(viewModel: viewModel)
        .onAppear { viewModel.load() }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack(alignment: .center) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.diaryPurple.opacity(0.2))
                        .frame(width: 36, height: 36)
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.diaryPurple)
                }
                Text("Мій Щоденник")
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
            Text("Поки немає записів")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.diaryPrimaryText)
            Text("Натисни + щоб створити перший запис")
                .font(.system(size: 14))
                .foregroundStyle(Color.diarySecondary)
            Button(action: onNewEntry) {
                Text("Створити запис")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.diaryPurple)
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
        .background(Color.diaryCard)
        .clipShape(Capsule())
    }

    private func dayLabel(_ count: Int) -> String {
        let mod = count % 10
        let mod100 = count % 100
        if mod100 >= 11 && mod100 <= 14 { return "днів" }
        if mod == 1 { return "день" }
        if mod >= 2 && mod <= 4 { return "дні" }
        return "днів"
    }
}

#Preview {
    DiaryListView(onNewEntry: {})
        .preferredColorScheme(.dark)
}
