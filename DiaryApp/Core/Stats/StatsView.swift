// MARK: - Stats View
// Статистика: summary cards, mood chart, activity heatmap, top tags.
import SwiftUI
import Charts

struct StatsView: View {
    @StateObject private var viewModel = StatsViewModel()

    var body: some View {
        ZStack {
            Color.diaryBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Month selector
                    monthSelector
                        .padding(.top, 16)

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

                        Chart(viewModel.moodChartData, id: \.day) { item in
                            BarMark(
                                x: .value("День", item.day),
                                y: .value("Настрій", item.mood)
                            )
                            .foregroundStyle(moodColor(for: item.mood))
                            .cornerRadius(4)
                        }
                        .chartYScale(domain: 1...5)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: 5)) { _ in
                                AxisValueLabel()
                                    .foregroundStyle(Color.diaryTertiary)
                            }
                        }
                        .chartYAxis(.hidden)
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
                                .fill(Color.diaryPurple)
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
        HStack(alignment: .top, spacing: 3) {
            ForEach(weeks.indices, id: \.self) { weekIdx in
                VStack(spacing: 3) {
                    ForEach(0..<7, id: \.self) { dayIdx in
                        let week = weeks[weekIdx]
                        if dayIdx < week.count, let date = week[dayIdx] {
                            let count = data[date] ?? 0
                            RoundedRectangle(cornerRadius: 2)
                                .fill(heatColor(for: count))
                                .frame(width: 11, height: 11)
                        } else {
                            Color.clear
                                .frame(width: 11, height: 11)
                        }
                    }
                }
            }
        }
    }

    private func heatColor(for count: Int) -> Color {
        switch count {
        case 0:        return Color.diaryPurple.opacity(0.1)
        case 1:        return Color.diaryPurple.opacity(0.35)
        case 2:        return Color.diaryPurple.opacity(0.6)
        default:       return Color.diaryPurple
        }
    }
}

#Preview {
    StatsView()
        .preferredColorScheme(.dark)
}
