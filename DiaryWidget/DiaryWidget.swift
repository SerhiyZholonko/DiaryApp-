// MARK: - Diary Widget Extension
// Small: streak + вогонь.
// Medium: streak + превью останнього запису + настрій.
// Дані читаються із App Group UserDefaults, які main app оновлює через WidgetDataStore.
import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct DiaryWidgetEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let hasEntry: Bool
    let preview: String
    let moodEmoji: String?
    let moodColorHex: String?
    let entryDate: Date?

    static let placeholder = DiaryWidgetEntry(
        date: .now,
        streak: 7,
        hasEntry: true,
        preview: "Сьогодні був чудовий день. Зустрів старих друзів…",
        moodEmoji: "😊",
        moodColorHex: "#06D6A0",
        entryDate: .now
    )

    static let empty = DiaryWidgetEntry(
        date: .now,
        streak: 0,
        hasEntry: false,
        preview: "",
        moodEmoji: nil,
        moodColorHex: nil,
        entryDate: nil
    )
}

// MARK: - Timeline Provider

struct DiaryWidgetProvider: TimelineProvider {

    // Читаємо напряму з App Group UserDefaults — не залежимо від main app коду
    private let appGroupID = "group.com.diary.diaryapp"
    private var ud: UserDefaults? { UserDefaults(suiteName: appGroupID) }

    func placeholder(in context: Context) -> DiaryWidgetEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (DiaryWidgetEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DiaryWidgetEntry>) -> Void) {
        let entry = makeEntry()
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func makeEntry() -> DiaryWidgetEntry {
        DiaryWidgetEntry(
            date: .now,
            streak:       ud?.integer(forKey: "widget_streak")          ?? 0,
            hasEntry:     ud?.bool(forKey: "widget_has_entry")          ?? false,
            preview:      ud?.string(forKey: "widget_preview")          ?? "",
            moodEmoji:    ud?.string(forKey: "widget_mood_emoji"),
            moodColorHex: ud?.string(forKey: "widget_mood_color"),
            entryDate:    ud?.object(forKey: "widget_entry_date") as? Date
        )
    }
}

// MARK: - Widget

@main
struct DiaryWidget: Widget {
    let kind = "DiaryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DiaryWidgetProvider()) { entry in
            DiaryWidgetEntryView(entry: entry)
                .containerBackground(Color(hex: "#0D0D1A"), for: .widget)
        }
        .configurationDisplayName("Diary")
        .description("Серія записів та останній запис.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Entry View (router)

struct DiaryWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DiaryWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:  SmallWidgetView(entry: entry)
        case .systemMedium: MediumWidgetView(entry: entry)
        default:            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget  (streak)

struct SmallWidgetView: View {
    let entry: DiaryWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Icon
            HStack(spacing: 6) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "#9B85FF"))
                Text("Diary")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "#9B85FF"))
            }

            Spacer()

            // Streak
            if entry.streak > 0 {
                VStack(alignment: .leading, spacing: 2) {
                    Text("🔥")
                        .font(.system(size: 32))
                    Text("\(entry.streak)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(entry.streak == 1 ? "день" : "днів")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "#8A8A9A"))
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("📖")
                        .font(.system(size: 28))
                    Text("Почни\nзаписувати")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(hex: "#8A8A9A"))
                        .lineLimit(2)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

// MARK: - Medium Widget  (streak + preview)

struct MediumWidgetView: View {
    let entry: DiaryWidgetEntry

    private var accentColor: Color {
        Color(hex: entry.moodColorHex ?? "#9B85FF")
    }

    var body: some View {
        HStack(spacing: 0) {

            // Left: streak
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: "#9B85FF"))

                Spacer()

                if entry.streak > 0 {
                    Text("🔥")
                        .font(.system(size: 26))
                    Text("\(entry.streak)")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(entry.streak == 1 ? "день" : "днів")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "#8A8A9A"))
                } else {
                    Text("📖")
                        .font(.system(size: 26))
                    Text("0")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "#8A8A9A"))
                    Text("днів")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "#8A8A9A"))
                }
            }
            .padding(14)
            .frame(width: 90, maxHeight: .infinity, alignment: .leading)

            // Divider
            Rectangle()
                .fill(Color(hex: "#2C2C3E"))
                .frame(width: 1)
                .padding(.vertical, 12)

            // Right: last entry
            VStack(alignment: .leading, spacing: 6) {
                if entry.hasEntry {
                    // Mood + date row
                    HStack(spacing: 6) {
                        if let emoji = entry.moodEmoji {
                            Text(emoji)
                                .font(.system(size: 15))
                        }
                        if let date = entry.entryDate {
                            Text(date, style: .relative)
                                .font(.system(size: 11))
                                .foregroundStyle(Color(hex: "#8A8A9A"))
                        }
                        Spacer()
                    }

                    Spacer().frame(height: 2)

                    // Preview text
                    Text(entry.preview.isEmpty ? "Немає тексту" : entry.preview)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(4)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    // Streak label bottom
                    if entry.streak > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Color(hex: "#FF6B35"))
                            Text("Серія \(entry.streak) \(entry.streak == 1 ? "день" : "днів")")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color(hex: "#8A8A9A"))
                        }
                    }

                } else {
                    // Empty state
                    VStack(alignment: .leading, spacing: 8) {
                        Spacer()
                        Text("Ще немає записів")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color(hex: "#8A8A9A"))
                        Text("Відкрий Diary та зроби перший запис сьогодні.")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "#5A5A7A"))
                            .lineLimit(3)
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Color(hex:) helper (widget has no access to main app extensions)

private extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch h.count {
        case 6: (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
        case 8: (r, g, b, a) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (r, g, b, a) = (0, 0, 0, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    DiaryWidget()
} timeline: {
    DiaryWidgetEntry.placeholder
    DiaryWidgetEntry.empty
}

#Preview(as: .systemMedium) {
    DiaryWidget()
} timeline: {
    DiaryWidgetEntry.placeholder
    DiaryWidgetEntry.empty
}
