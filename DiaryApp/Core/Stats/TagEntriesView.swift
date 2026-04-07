// MARK: - Tag Entries View
// Список записів відфільтрованих за конкретним тегом.
import SwiftUI

struct TagEntriesView: View {
    let tag: String
    let onEdit: (DiaryEntry) -> Void

    @EnvironmentObject private var theme: AppTheme
    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        ZStack {
            Color.diaryBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(LinearGradient(
                                colors: [theme.accent.opacity(0.35), theme.accent.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 36, height: 36)
                        Image(systemName: "tag.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(theme.accent)
                    }
                    Text("#\(tag)")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.diaryPrimaryText)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

                if viewModel.results.isEmpty {
                    Spacer()
                    Text("Немає записів з тегом #\(tag)")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.diarySecondary)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("\(viewModel.results.count) \(entryLabel(viewModel.results.count))")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.diarySecondary)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 12)

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
                            Spacer().frame(height: 40)
                        }
                    }
                }
            }
        }
        .onAppear {
            viewModel.selectedFilter = .tag(tag)
            viewModel.load()
        }
    }

    private func entryLabel(_ count: Int) -> String {
        let mod10 = count % 10
        let mod100 = count % 100
        if mod100 >= 11 && mod100 <= 14 { return "записів" }
        if mod10 == 1 { return "запис" }
        if mod10 >= 2 && mod10 <= 4 { return "записи" }
        return "записів"
    }
}
