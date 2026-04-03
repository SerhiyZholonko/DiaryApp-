// MARK: - Stats ViewModel
import Foundation
import Combine
import Factory

@MainActor
final class StatsViewModel: ObservableObject, ErrorDisplayable, AlertDisplayable {
    @Published var entries: [DiaryEntry] = []
    @Published var isLoading = false
    @Published var selectedMonth: Date = .now
    @Published var error: Error?
    @Published var alert: AppAlert?

    @Injected(\.diaryStore)  private var diaryStore: DiaryStoreProtocol
    @Injected(\.streakStore) private var streakStore: StreakStoreProtocol

    var totalEntries: Int { entries.count }

    var totalWords: Int { entries.reduce(0) { $0 + $1.wordCount } }

    var currentStreak: Int { streakStore.currentStreak }

    // Mood per day for current month
    var moodChartData: [(day: Int, mood: Double)] {
        let calendar = Calendar.current
        let monthEntries = entries.filter {
            calendar.isDate($0.createdAt, equalTo: selectedMonth, toGranularity: .month)
        }
        let grouped = Dictionary(grouping: monthEntries) {
            calendar.component(.day, from: $0.createdAt)
        }
        return grouped.compactMap { day, dayEntries -> (Int, Double)? in
            guard let avgMood = dayEntries.compactMap({ $0.mood?.rawValue }).map(Double.init).average else { return nil }
            return (day, avgMood)
        }
        .sorted { $0.day < $1.day }
    }

    // Activity heatmap: date → entry count
    var activityData: [Date: Int] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) {
            calendar.startOfDay(for: $0.createdAt)
        }
        return grouped.mapValues { $0.count }
    }

    // Top tags
    var topTags: [(tag: String, count: Int)] {
        var tagCounts: [String: Int] = [:]
        entries.flatMap { $0.tags }.forEach { tagCounts[$0, default: 0] += 1 }
        let pairs: [(tag: String, count: Int)] = tagCounts.map { (tag: $0.key, count: $0.value) }
        return pairs.sorted { $0.count > $1.count }.prefix(6).map { $0 }
    }

    func load() {
        Task(operation: {
            isLoading = true
            defer { isLoading = false }
            do {
                entries = try await diaryStore.fetchEntries()
            } catch {
                self.error = error
            }
        })
    }
}

private extension Array where Element == Double {
    var average: Double? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Double(count)
    }
}
