// MARK: - Stats ViewModel
import Foundation
import Combine
import Factory

@MainActor
final class StatsViewModel: ObservableObject, ErrorDisplayable, AlertDisplayable {
    @Published var isLoading = false
    @Published var selectedMonth: Date = .now
    @Published var error: Error?
    @Published var alert: AppAlert?

    // Кешовані результати — не перераховуються при кожному рендері
    @Published private(set) var totalEntries: Int = 0
    @Published private(set) var totalWords: Int = 0
    @Published private(set) var moodChartData: [(day: Int, mood: Double)] = []
    @Published private(set) var activityData: [Date: Int] = [:]
    @Published private(set) var topTags: [(tag: String, count: Int)] = []
    @Published private(set) var currentStreak: Int = 0

    @Injected(\.diaryStore)  private var diaryStore: DiaryStoreProtocol
    @Injected(\.streakStore) private var streakStore: StreakStoreProtocol

    private var entries: [DiaryEntry] = []

    func load() {
        Task {
            isLoading = true
            defer { isLoading = false }
            do {
                entries = try await diaryStore.fetchEntries()
                computeStats()
            } catch {
                self.error = error
            }
        }
    }

    // MARK: - Private

    func computeStats() {
        let entries = self.entries
        let month = selectedMonth
        currentStreak = streakStore.currentStreak
        totalEntries  = entries.count
        totalWords    = entries.reduce(0) { $0 + $1.wordCount }
        moodChartData = Self.buildMoodChart(entries: entries, month: month)
        activityData  = Self.buildActivityData(entries: entries)
        topTags       = Self.buildTopTags(entries: entries)
    }

    private static func buildMoodChart(entries: [DiaryEntry], month: Date) -> [(day: Int, mood: Double)] {
        let calendar = Calendar.current
        let monthEntries = entries.filter {
            calendar.isDate($0.createdAt, equalTo: month, toGranularity: .month)
        }
        let grouped = Dictionary(grouping: monthEntries) {
            calendar.component(.day, from: $0.createdAt)
        }
        return grouped.compactMap { day, dayEntries -> (Int, Double)? in
            let values = dayEntries.compactMap { $0.mood?.rawValue }.map(Double.init)
            guard !values.isEmpty else { return nil }
            return (day, values.reduce(0, +) / Double(values.count))
        }
        .sorted { $0.day < $1.day }
    }

    private static func buildActivityData(entries: [DiaryEntry]) -> [Date: Int] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) {
            calendar.startOfDay(for: $0.createdAt)
        }
        return grouped.mapValues { $0.count }
    }

    private static func buildTopTags(entries: [DiaryEntry]) -> [(tag: String, count: Int)] {
        var tagCounts: [String: Int] = [:]
        entries.flatMap { $0.tags }.forEach { tagCounts[$0, default: 0] += 1 }
        return tagCounts.map { (tag: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(6)
            .map { $0 }
    }
}
