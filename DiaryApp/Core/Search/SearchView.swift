// MARK: - Search View
// Пошук записів із фільтрами.
import SwiftUI

struct SearchView: View {
    let onEdit: (DiaryEntry) -> Void

    @EnvironmentObject private var theme: AppTheme
    @EnvironmentObject private var lang: LanguageManager
    @StateObject private var viewModel = SearchViewModel()
    @FocusState private var searchFocused: Bool

    private let filters: [SearchFilter] = [
        .all, .today, .thisWeek,
        .mood(.excellent), .mood(.good), .mood(.neutral), .mood(.bad), .mood(.awful)
    ]

    var body: some View {
        ZStack {
            Color.diaryBackground.ignoresSafeArea()
                .onTapGesture { searchFocused = false }

            VStack(spacing: 0) {
                // Title
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(LinearGradient(
                                colors: [theme.accent.opacity(0.35), theme.accent.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 36, height: 36)
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16))
                            .foregroundStyle(theme.accent)
                    }
                    Text(lang.l("Search", "Пошук"))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.diaryPrimaryText)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // Search bar
                HStack(spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Color.diarySecondary)
                        TextField(lang.l("Search entries...", "Пошук записів..."), text: $viewModel.query)
                            .font(.system(size: 16))
                            .foregroundStyle(Color.diaryPrimaryText)
                            .tint(theme.accent)
                            .focused($searchFocused)
                            .submitLabel(.search)
                            .onSubmit { searchFocused = false }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.diaryCard)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    if searchFocused {
                        Button(lang.l("Cancel", "Скасувати")) {
                            searchFocused = false
                            viewModel.query = ""
                        }
                        .font(.system(size: 15))
                        .foregroundStyle(theme.accent)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: searchFocused)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(filters, id: \.stableId) { filter in
                            FilterChip(
                                label: filter.label,
                                isSelected: viewModel.selectedFilter == filter,
                                action: { viewModel.selectedFilter = filter }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }

                // Tag filters from entries
                if !viewModel.results.isEmpty {
                    let allTags = Array(Set(viewModel.results.flatMap { $0.tags })).sorted().prefix(6)
                    if !allTags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                Text(lang.l("Tags:", "Теги:"))
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.diarySecondary)
                                ForEach(allTags, id: \.self) { tag in
                                    TagChip(text: "#\(tag)")
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.top, 8)
                    }
                }

                if viewModel.query.isEmpty && viewModel.selectedFilter == .all {
                    emptyPrompt
                } else {
                    resultsList
                }
            }
        }
        .onAppear { viewModel.load() }
    }

    private var emptyPrompt: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(Color.diarySecondary)
            Text(lang.l("Enter a query to search", "Введи запит для пошуку"))
                .font(.system(size: 16))
                .foregroundStyle(Color.diarySecondary)
            Spacer()
        }
    }

    private var resultsList: some View {
        Group {
            if viewModel.results.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Text(lang.l("Nothing found", "Нічого не знайдено"))
                        .font(.system(size: 16))
                        .foregroundStyle(Color.diarySecondary)
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(lang.l("Results (\(viewModel.results.count))", "Результати (\(viewModel.results.count))"))
                            .font(.system(size: 13))
                            .foregroundStyle(Color.diarySecondary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)

                        ForEach(viewModel.results) { entry in
                            DiaryEntryCard(
                                entry: entry,
                                onEdit: { onEdit(entry) },
                                onDelete: {}
                            )
                            .padding(.horizontal, 20)
                            .padding(.bottom, 12)
                            .onTapGesture { onEdit(entry) }
                        }
                        Spacer().frame(height: 90)
                    }
                }
                .scrollDismissesKeyboard(.immediately)
            }
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    @EnvironmentObject private var theme: AppTheme

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : Color.diarySecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? theme.accent : Color.diaryCard)
                .clipShape(Capsule())
        }
    }
}

#Preview {
    SearchView(onEdit: { _ in })
        .environmentObject(AppTheme())
        .preferredColorScheme(.dark)
}
