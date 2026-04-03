// MARK: - Diary Entry Card
import SwiftUI

struct DiaryEntryCard: View {
    let entry: DiaryEntry
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirm = false

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        let calendar = Calendar.current
        if calendar.isDateInToday(entry.createdAt) {
            formatter.dateFormat = "'Сьогодні,' HH:mm"
        } else if calendar.isDateInYesterday(entry.createdAt) {
            formatter.dateFormat = "'Вчора,' HH:mm"
        } else {
            formatter.dateFormat = "d MMMM, HH:mm"
        }
        return formatter.string(from: entry.createdAt)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(timeString)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.diarySecondary)
                Spacer()
                if let mood = entry.mood {
                    Text(mood.emoji).font(.system(size: 18))
                }
            }

            Text(MarkdownRenderer.preview(entry.text))
                .font(.system(size: 15))
                .foregroundStyle(Color.diaryPrimaryText)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                ForEach(entry.tags.prefix(3), id: \.self) { tag in
                    TagChip(text: "#\(tag)")
                }
                Spacer()
                if entry.wordCount > 0 {
                    Text("\(entry.wordCount) \(wordLabel(entry.wordCount))")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.diaryTertiary)
                }
            }
        }
        .padding(16)
        .background(Color.diaryCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        // Swipe-to-delete
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("Видалити", systemImage: "trash")
            }
            Button(action: onEdit) {
                Label("Редагувати", systemImage: "pencil")
            }
            .tint(Color.diaryPurple)
        }
        // Long-press context menu
        .contextMenu {
            Button(action: onEdit) {
                Label("Редагувати", systemImage: "pencil")
            }
            Divider()
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("Видалити", systemImage: "trash")
            }
        }
        .confirmationDialog(
            "Видалити запис?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Видалити", role: .destructive, action: onDelete)
            Button("Скасувати", role: .cancel) {}
        } message: {
            Text("Цю дію неможливо скасувати")
        }
    }

    private func wordLabel(_ count: Int) -> String {
        let mod10 = count % 10
        let mod100 = count % 100
        if mod100 >= 11 && mod100 <= 14 { return "слів" }
        if mod10 == 1 { return "слово" }
        if mod10 >= 2 && mod10 <= 4 { return "слова" }
        return "слів"
    }
}

// MARK: - Tag Chip
struct TagChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color.diaryPurpleLight)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.diaryPurple.opacity(0.2))
            .clipShape(Capsule())
    }
}

#Preview {
    DiaryEntryCard(
        entry: DiaryEntry(
            text: "Сьогодні був **продуктивний день**. Закінчив роботу над архітектурою.",
            mood: .good,
            tags: ["робота", "код"]
        ),
        onEdit: {},
        onDelete: {}
    )
    .padding()
    .background(Color.diaryBackground)
    .preferredColorScheme(.dark)
}
