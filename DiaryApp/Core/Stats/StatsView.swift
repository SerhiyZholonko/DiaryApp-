// MARK: - Stats View
// Статистика: summary cards, mood chart, activity heatmap, top tags.
import SwiftUI
import Charts

struct StatsView: View {
    let onEdit: (DiaryEntry) -> Void

    @EnvironmentObject private var theme: AppTheme
    @EnvironmentObject private var lang: LanguageManager
    @Environment(\.horizontalSizeClass) private var sizeClass
    @StateObject private var viewModel = StatsViewModel()
    @State private var selectedTag: String? = nil

    private var isRegular: Bool { sizeClass == .regular }
    private var chartHeight: CGFloat     { isRegular ? 220 : 140 }
    private var emojiAxisWidth: CGFloat  { isRegular ? 36 : 24 }
    private var emojiSize: CGFloat       { isRegular ? 20 : 12 }
    private var sectionTitleSize: CGFloat { isRegular ? 20 : 16 }
    private var contentMaxWidth: CGFloat { isRegular ? 900 : .infinity }

    var body: some View {
        ZStack {
            Color.diaryBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Sticky header
                VStack(alignment: .leading, spacing: isRegular ? 16 : 12) {
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: isRegular ? 14 : 10)
                                .fill(LinearGradient(
                                    colors: [theme.accent.opacity(0.35), theme.accent.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: isRegular ? 48 : 36, height: isRegular ? 48 : 36)
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: isRegular ? 22 : 16))
                                .foregroundStyle(theme.accent)
                        }
                        Text(lang.l("Statistics", "Статистика"))
                            .font(.system(size: isRegular ? 30 : 22, weight: .bold))
                            .foregroundStyle(Color.diaryPrimaryText)
                        Spacer()
                    }
                    .padding(.top, 16)

                    monthSelector
                }
                .padding(.horizontal, isRegular ? 40 : 20)
                .padding(.bottom, 12)
                .background(Color.diaryBackground)
                .frame(maxWidth: contentMaxWidth)
                .frame(maxWidth: .infinity)

            ScrollView {
                VStack(alignment: .leading, spacing: isRegular ? 28 : 20) {
                    // Summary cards
                    HStack(spacing: 12) {
                        StatCard(title: lang.l("Entries", "Записів"),  value: "\(viewModel.totalEntries)", icon: "doc.text.fill")
                        StatCard(title: lang.l("Words", "Слів"),    value: formatNumber(viewModel.totalWords), icon: "text.alignleft")
                        StatCard(title: lang.l("Streak", "Серія"),   value: "\(viewModel.currentStreak)", icon: "flame.fill", iconColor: streakFlameColor(viewModel.currentStreak))
                    }

                    // Mood chart
                    moodChart

                    // Activity heatmap
                    activityHeatmap

                    // Top tags
                    topTagsSection

                    Spacer().frame(height: 90)
                }
                .padding(.horizontal, isRegular ? 40 : 20)
                .frame(maxWidth: contentMaxWidth)
                .frame(maxWidth: .infinity)
            }
            } // end outer VStack
        }
        .onAppear { viewModel.load() }
        .onChange(of: viewModel.selectedMonth) { _ in viewModel.computeStats() }
        .sheet(item: Binding(
            get: { selectedTag.map { TagItem(tag: $0) } },
            set: { selectedTag = $0?.tag }
        )) { item in
            TagEntriesView(tag: item.tag, onEdit: { entry in
                selectedTag = nil
                onEdit(entry)
            })
            .environmentObject(theme)
            .environmentObject(lang)
        }
    }

    // MARK: - Month selector
    private var monthSelector: some View {
        HStack {
            Spacer()
            Menu {
                ForEach(-11...0, id: \.self) { offset in
                    if let date = Calendar.current.date(byAdding: .month, value: offset, to: .now) {
                        Button(action: { viewModel.selectedMonth = date }) {
                            Text(date.formatted(.dateTime.month(.wide).year().locale(lang.locale)).capitalized)
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(viewModel.selectedMonth.formatted(
                        .dateTime.month(.wide).year().locale(lang.locale)
                    ).capitalized)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.diaryPrimaryText)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.diarySecondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.diaryCard)
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - Mood chart
    private var moodChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(lang.l("Mood This Month", "Настрій цього місяця"))
                .font(.system(size: sectionTitleSize, weight: .semibold))
                .foregroundStyle(Color.diaryPrimaryText)

            ZStack {
                if viewModel.moodChartData.isEmpty {
                    Text(lang.l("No data for this month", "Немає даних за цей місяць"))
                        .font(.system(size: 14))
                        .foregroundStyle(Color.diarySecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: chartHeight)
                } else {
                    // Mood emoji axis
                    HStack(spacing: 0) {
                        VStack(spacing: 0) {
                            ForEach([MoodLevel.excellent, .good, .neutral, .bad, .awful], id: \.rawValue) { mood in
                                Text(mood.emoji)
                                    .font(.system(size: emojiSize))
                                    .frame(maxHeight: .infinity)
                            }
                        }
                        .frame(width: emojiAxisWidth)
                        .frame(height: chartHeight)

                        GeometryReader { geo in
                            let days = daysInSelectedMonth
                            // Залишаємо ~32pt для Y-лейблів; решта — сітка барів
                            let chartWidth = geo.size.width - 32
                            let barWidth   = max(4, (chartWidth / CGFloat(days)) * 0.65)

                            Chart(viewModel.moodChartData, id: \.day) { item in
                                BarMark(
                                    x: .value(lang.l("Day", "День"), item.day),
                                    y: .value(lang.l("Mood", "Настрій"), item.mood),
                                    width: .fixed(barWidth)
                                )
                                .foregroundStyle(moodColor(for: item.mood))
                                .cornerRadius(max(2, barWidth / 3))
                            }
                            .chartYScale(domain: 1...5)
                            .chartXScale(domain: 1...days)
                            .chartXAxis {
                                AxisMarks(values: stride(from: 5, through: days, by: 5).map { $0 }) { _ in
                                    AxisValueLabel()
                                        .foregroundStyle(Color.diaryTertiary)
                                }
                            }
                            .chartYAxis(.hidden)
                            .frame(width: geo.size.width, height: chartHeight)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: chartHeight)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(16)
            .background(Color.diaryCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
        }
    }

    // MARK: - Activity heatmap
    private var activityHeatmap: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(lang.l("Activity (Year)", "Активність (рік)"))
                .font(.system(size: sectionTitleSize, weight: .semibold))
                .foregroundStyle(Color.diaryPrimaryText)

            if isRegular {
                // Mac/iPad: fill available width, no horizontal scroll
                GeometryReader { geo in
                    let padding: CGFloat = 32
                    let available = geo.size.width - padding
                    let spacing: CGFloat = 4
                    let cols = 53
                    let cell = floor((available - CGFloat(cols - 1) * spacing) / CGFloat(cols))
                    let rows = 7
                    let totalHeight = cell * CGFloat(rows) + spacing * CGFloat(rows - 1)

                    HeatmapView(data: viewModel.activityData, fixedCellSize: cell, fixedSpacing: spacing)
                        .padding(padding / 2)
                        .frame(height: totalHeight + padding)
                }
                .frame(height: {
                    let cell: CGFloat = 18
                    let spacing: CGFloat = 4
                    return cell * 7 + spacing * 6 + 32
                }())
                .background(Color.diaryCard)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HeatmapView(data: viewModel.activityData)
                        .padding(16)
                }
                .defaultScrollAnchor(.trailing)
                .background(Color.diaryCard)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
            }
        }
    }

    // MARK: - Top tags
    private var topTagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(lang.l("Top Tags", "Топ теги"))
                .font(.system(size: sectionTitleSize, weight: .semibold))
                .foregroundStyle(Color.diaryPrimaryText)

            if viewModel.topTags.isEmpty {
                Text(lang.l("No tags yet", "Ще немає тегів"))
                    .font(.system(size: isRegular ? 16 : 14))
                    .foregroundStyle(Color.diarySecondary)
            } else {
                let maxCount = viewModel.topTags.first?.count ?? 1
                VStack(spacing: isRegular ? 16 : 12) {
                    ForEach(viewModel.topTags, id: \.tag) { item in
                        Button {
                            selectedTag = item.tag
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("#\(item.tag)")
                                        .font(.system(size: isRegular ? 17 : 14, weight: .medium))
                                        .foregroundStyle(Color.diaryPrimaryText)
                                    Spacer()
                                    HStack(spacing: 4) {
                                        Text("\(item.count) \(lang.l(item.count == 1 ? "entry" : "entries", item.count == 1 ? "запис" : "записів"))")
                                            .font(.system(size: isRegular ? 15 : 13))
                                            .foregroundStyle(Color.diarySecondary)
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: isRegular ? 13 : 11))
                                            .foregroundStyle(Color.diaryTertiary)
                                    }
                                }
                                GeometryReader { geo in
                                    RoundedRectangle(cornerRadius: isRegular ? 5 : 4)
                                        .fill(LinearGradient(
                                            colors: [theme.accent, theme.accent.opacity(0.6)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ))
                                        .frame(
                                            width: geo.size.width * CGFloat(item.count) / CGFloat(maxCount),
                                            height: isRegular ? 8 : 6
                                        )
                                }
                                .frame(height: isRegular ? 8 : 6)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(isRegular ? 20 : 16)
                .background(Color.diaryCard)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var daysInSelectedMonth: Int {
        Calendar.current.range(of: .day, in: .month, for: viewModel.selectedMonth)?.count ?? 31
    }

    private func streakFlameColor(_ days: Int) -> Color {
        switch days {
        case 1...2:   return .moodNeutral
        case 3...6:   return .moodBad
        case 7...13:  return .streakFlameHigh
        case 14...29: return .moodAwful
        default:      return .streakFlameExtreme
        }
    }

    private func moodColor(for value: Double) -> Color {
        switch value {
        case ..<1.5: return .moodAwful
        case ..<2.5: return .moodBad
        case ..<3.5: return .moodNeutral
        case ..<4.5: return .moodGood
        default:     return .moodExcellent
        }
    }

    private func formatNumber(_ n: Int) -> String {
        if n >= 1000 { return String(format: "%.1fk", Double(n) / 1000) }
        return "\(n)"
    }
}

// MARK: - StatCard
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var iconColor: Color? = nil

    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isRegular: Bool { sizeClass == .regular }

    var body: some View {
        VStack(spacing: isRegular ? 8 : 4) {
            HStack(spacing: 4) {
                Text(value)
                    .font(.system(size: isRegular ? 32 : 22, weight: .bold))
                    .foregroundStyle(Color.diaryPrimaryText)
                if let color = iconColor {
                    Image(systemName: icon)
                        .font(.system(size: isRegular ? 20 : 14, weight: .semibold))
                        .foregroundStyle(color)
                }
            }
            Text(title)
                .font(.system(size: isRegular ? 15 : 12))
                .foregroundStyle(Color.diarySecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, isRegular ? 24 : 16)
        .background(Color.diaryCard)
        .clipShape(RoundedRectangle(cornerRadius: isRegular ? 18 : 14))
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}

// MARK: - HeatmapView
struct HeatmapView: View {
    let data: [Date: Int]
    var fixedCellSize: CGFloat? = nil
    var fixedSpacing: CGFloat? = nil

    @EnvironmentObject private var theme: AppTheme
    @Environment(\.horizontalSizeClass) private var sizeClass
    private let calendar = Calendar.current
    private let columns = 53
    private let rows = 7

    private var cellSize: CGFloat  { fixedCellSize ?? (sizeClass == .regular ? 16 : 11) }
    private var cellSpacing: CGFloat { fixedSpacing ?? (sizeClass == .regular ? 4 : 3) }
    private var cellRadius: CGFloat  { sizeClass == .regular ? 3 : 2 }

    private var weeks: [[Date?]] {
        let today = calendar.startOfDay(for: .now)
        let startDate = calendar.date(byAdding: .day, value: -(columns * rows - 1), to: today)!

        var allDays: [Date?] = []
        var current = startDate
        while current <= today {
            allDays.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }

        // Pad to fill full weeks
        let leadingPad = calendar.component(.weekday, from: startDate) - 1
        allDays = Array(repeating: nil, count: leadingPad) + allDays

        // Split into weeks
        return stride(from: 0, to: allDays.count, by: 7).map {
            Array(allDays[$0..<min($0 + 7, allDays.count)])
        }
    }

    var body: some View {
        // Обчислюємо один раз — уникаємо 372 повторних викликів Calendar
        let computedWeeks = weeks
        let accent = theme.accent
        let size = cellSize
        let spacing = cellSpacing
        let radius = cellRadius

        HStack(alignment: .top, spacing: spacing) {
            ForEach(computedWeeks.indices, id: \.self) { weekIdx in
                let week = computedWeeks[weekIdx]
                VStack(spacing: spacing) {
                    ForEach(0..<7, id: \.self) { dayIdx in
                        if dayIdx < week.count, let date = week[dayIdx] {
                            let count = data[date] ?? 0
                            RoundedRectangle(cornerRadius: radius)
                                .fill(heatColor(count, accent: accent))
                                .frame(width: size, height: size)
                        } else {
                            Color.clear.frame(width: size, height: size)
                        }
                    }
                }
            }
        }
    }

    private func heatColor(_ count: Int, accent: Color) -> Color {
        switch count {
        case 0:    return accent.opacity(0.1)
        case 1:    return accent.opacity(0.35)
        case 2:    return accent.opacity(0.6)
        default:   return accent
        }
    }
}

// MARK: - Tag Item (Identifiable wrapper for sheet)
private struct TagItem: Identifiable {
    let tag: String
    var id: String { tag }
}

#Preview {
    StatsView(onEdit: { _ in })
        .environmentObject(AppTheme())
        .preferredColorScheme(.dark)
}
