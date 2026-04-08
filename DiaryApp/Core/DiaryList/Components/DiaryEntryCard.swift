// MARK: - Diary Entry Card
import SwiftUI

struct DiaryEntryCard: View {
    let entry: DiaryEntry
    let onEdit: () -> Void
    let onDelete: () -> Void

    @EnvironmentObject private var theme: AppTheme
    @EnvironmentObject private var lang: LanguageManager
    @State private var showDeleteConfirm = false

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.locale = lang.locale
        let calendar = Calendar.current
        if calendar.isDateInToday(entry.createdAt) {
            formatter.dateFormat = lang.l("'Today,' h:mm a", "'Сьогодні,' HH:mm")
        } else if calendar.isDateInYesterday(entry.createdAt) {
            formatter.dateFormat = lang.l("'Yesterday,' h:mm a", "'Вчора,' HH:mm")
        } else {
            formatter.dateFormat = lang.l("MMM d, h:mm a", "d MMM, HH:mm")
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
                .truncationMode(.tail)

            // Media preview thumbnails
            if !entry.attachments.isEmpty {
                mediaPreview
            }

            HStack(spacing: 8) {
                ForEach(entry.tags.prefix(3), id: \.self) { tag in
                    TagChip(text: "#\(tag)")
                }
                Spacer()
                if !entry.attachments.isEmpty {
                    Label("\(entry.attachments.count)", systemImage: "photo")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.diaryTertiary)
                } else if entry.wordCount > 0 {
                    Text("\(entry.wordCount) \(wordLabel(entry.wordCount))")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.diaryTertiary)
                }
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                stops: [
                    .init(color: theme.accent.opacity(0.07), location: 0),
                    .init(color: Color.diaryCard, location: 0.45)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.09), radius: 12, x: 0, y: 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label(lang.l("Delete", "Видалити"), systemImage: "trash")
            }
            Button(action: onEdit) {
                Label(lang.l("Edit", "Редагувати"), systemImage: "pencil")
            }
            .tint(theme.accent)
        }
        .contextMenu {
            Button(action: onEdit) {
                Label(lang.l("Edit", "Редагувати"), systemImage: "pencil")
            }
            Divider()
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label(lang.l("Delete", "Видалити"), systemImage: "trash")
            }
        }
        .confirmationDialog(
            lang.l("Delete entry?", "Видалити запис?"),
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(lang.l("Delete", "Видалити"), role: .destructive, action: onDelete)
            Button(lang.l("Cancel", "Скасувати"), role: .cancel) {}
        } message: {
            Text(lang.l("This action cannot be undone", "Цю дію не можна скасувати"))
        }
    }

    // MARK: - Media Preview

    private var mediaPreview: some View {
        HStack(spacing: 6) {
            ForEach(Array(entry.attachments.prefix(4).enumerated()), id: \.element.id) { _, att in
                MediaThumbnailCell(
                    attachment: att,
                    entryId: entry.id,
                    showRemove: false,
                    size: 64,
                    onRemove: {},
                    onTap: {}
                )
                .allowsHitTesting(false)
            }

            if entry.attachments.count > 4 {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.diaryCard)
                        .frame(width: 64, height: 64)
                    Text("+\(entry.attachments.count - 4)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.diarySecondary)
                }
            }
        }
    }

    private func wordLabel(_ count: Int) -> String {
        lang.l(count == 1 ? "word" : "words", count == 1 ? "слово" : "слів")
    }
}

// MARK: - Tag Chip
struct TagChip: View {
    let text: String

    @EnvironmentObject private var theme: AppTheme

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(theme.accentLight)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(theme.accent.opacity(0.2))
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
    .environmentObject(AppTheme())
    .preferredColorScheme(.dark)
}
