// MARK: - Stats View
// Статистика: summary cards, mood chart, activity heatmap, top tags.
import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject private var theme: AppTheme
    @StateObject private var viewModel = StatsViewModel()

    var body: some View {
        ZStack {
            Color.diaryBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(theme.accent.opacity(0.2))
                                .frame(width: 36, height: 36)
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(theme.accent)
                        }
                        Text("Статистика")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color.diaryPrimaryText)
                        Spacer()
                    }
                    .padding(.top, 16)

                    // Month selector
                    monthSelector

                    // Summary cards
                    HStack(spacing: 12) {
                        StatCard(title: "Записів",  value: "\(viewModel.totalEntries)", icon: "doc.text.fill")
                        StatCard(title: "Слів",     value: formatNumber(viewModel.totalWords), icon: "text.alignleft")
                        StatCard(title: "Серія",    value: "\(viewModel.currentStreak)🔥", icon: "flame.fill")
                    }

                    // Mood chart
                    moodChart

                    // Activity heatmap
                    activityHeatmap

                    // Top tags
                    topTagsSection

                    Spacer().frame(height: 90)
                }
                .padding(.horizontal, 20)
            }
        }
        .onAppear { viewModel.load() }
        .onChange(of: viewModel.selectedMonth) { _ in viewModel.computeStats() }
    }

    // MARK: - Month selector
    private var monthSelector: some View {
        HStack {
            Spacer()
            Menu {
                ForEach(-11...0, id: \.self) { offset in
                    if let date = Calendar.current.date(byAdding: .month, value: offset, to: .now) {
                        Button(action: { viewModel.selectedMonth = date }) {
                            Text(date.formatted(.dateTime.month(.wide).year().locale(Locale(identifier: "uk_UA"))).capitalized)
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(viewModel.selectedMonth.formatted(
                        .dateTime.month(.wide).year().locale(Locale(identifier: "uk_UA"))
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
            Text("Настрій за місяць")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.diaryPrimaryText)

            ZStack {
                if viewModel.moodChartData.isEmpty {
                    Text("Немає даних за цей місяць")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.diarySecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 140)
                } else {
                    // Mood emoji axis
                    HStack(spacing: 0) {
                        VStack(spacing: 0) {
                            ForEach([MoodLevel.excellent, .good, .neutral, .bad, .awful], id: \.rawValue) { mood in
                                Text(mood.emoji)
                                    .font(.system(size: 12))
                                    .frame(maxHeight: .infinity)
                            }
                        }
                        .frame(width: 24)
                        .frame(height: 140)

                        GeometryReader { geo in
                            let days = daysInSelectedMonth
                            // Залишаємо ~32pt для Y-лейблів; решта — сітка барів
                            let chartWidth = geo.size.width - 32
                            let barWidth   = max(4, (chartWidth / CGFloat(days)) * 0.65)

                            Chart(viewModel.moodChartData, id: \.day) { item in
                                BarMark(
                                    x: .value("День", item.day),
                                    y: .value("Настрій", item.mood),
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
                            .frame(width: geo.size.width, height: 140)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 140)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(16)
            .background(Color.diaryCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Activity heatmap
    private var activityHeatmap: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Активність (рік)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.diaryPrimaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HeatmapView(data: viewModel.activityData)
                    .padding(16)
            }
            .defaultScrollAnchor(.trailing)
            .background(Color.diaryCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Top tags
    private var topTagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Топ теги")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.diaryPrimaryText)

            if viewModel.topTags.isEmpty {
                Text("Немає тегів")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.diarySecondary)
            } else {
                let maxCount = viewModel.topTags.first?.count ?? 1
                VStack(spacing: 12) {
                    ForEach(viewModel.topTags, id: \.tag) { item in
                        HStack {
                            Text("#\(item.tag)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.diaryPrimaryText)
                            Spacer()
                            Text("\(item.count) зап.")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.diarySecondary)
                        }
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(theme.accent)
                                .frame(width: geo.size.width * CGFloat(item.count) / CGFloat(maxCount), height: 6)
                        }
                        .frame(height: 6)
                    }
                }
                .padding(16)
                .background(Color.diaryCard)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var daysInSelectedMonth: Int {
        Calendar.current.range(of: .day, in: .month, for: viewModel.selectedMonth)?.count ?? 31
    }

    private func moodColor(for value: Double) -> Color {
        switch value {
        case ..<1.5: return Color(hex: "#FF4B4B")
        case ..<2.5: return Color(hex: "#FF8C42")
        case ..<3.5: return Color(hex: "#FFD166")
        case ..<4.5: return Color(hex: "#06D6A0")
        default:     return Color(hex: "#4ECDC4")
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

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.diaryPrimaryText)
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(Color.diarySecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.diaryCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - HeatmapView
struct HeatmapView: View {
    let data: [Date: Int]

    @EnvironmentObject private var theme: AppTheme
    private let calendar = Calendar.current
    private let columns = 53
    private let rows = 7

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

        HStack(alignment: .top, spacing: 3) {
            ForEach(computedWeeks.indices, id: \.self) { weekIdx in
                let week = computedWeeks[weekIdx]
                VStack(spacing: 3) {
                    ForEach(0..<7, id: \.self) { dayIdx in
                        if dayIdx < week.count, let date = week[dayIdx] {
                            let count = data[date] ?? 0
                            RoundedRectangle(cornerRadius: 2)
                                .fill(heatColor(count, accent: accent))
                                .frame(width: 11, height: 11)
                        } else {
                            Color.clear.frame(width: 11, height: 11)
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

#Preview {
    StatsView()
        .environmentObject(AppTheme())
        .preferredColorScheme(.dark)
}
