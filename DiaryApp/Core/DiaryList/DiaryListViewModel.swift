// MARK: - DiaryList ViewModel
import Foundation
import Combine
import Factory

@MainActor
final class DiaryListViewModel: ObservableObject, ErrorDisplayable, AlertDisplayable {
    @Published var entries: [DiaryEntry] = []
    @Published var todayMood: MoodLevel?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var alert: AppAlert?

    @Injected(\.diaryStore)  private var diaryStore: DiaryStoreProtocol
    @Injected(\.streakStore) private var streakStore: StreakStoreProtocol

    var currentStreak: Int { streakStore.currentStreak }

    init() {
        NotificationCenter.default.addObserver(
            forName: .diaryEntryUpdated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.load() }
        }
    }

    // Записи, згруповані за місяць
    var groupedEntries: [(key: String, entries: [DiaryEntry])] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.dateFormat = "LLLL yyyy"

        let grouped = Dictionary(grouping: entries) { entry in
            formatter.string(from: entry.createdAt).capitalized
        }
        return grouped
            .map { (key: $0.key, entries: $0.value.sorted { $0.createdAt > $1.createdAt }) }
            .sorted { a, b in
                (a.entries.first?.createdAt ?? .distantPast) > (b.entries.first?.createdAt ?? .distantPast)
            }
    }

    func load() {
        Task(operation: {
            isLoading = true
            defer { isLoading = false }
            do {
                entries = try await diaryStore.fetchEntries()
                loadTodayMood()
            } catch {
                self.error = error
            }
        })
    }

    func delete(_ entry: DiaryEntry) {
        Task(operation: {
            do {
                try await diaryStore.deleteEntry(id: entry.id)
                entries.removeAll { $0.id == entry.id }
            } catch {
                self.error = error
            }
        })
    }

    private func loadTodayMood() {
        todayMood = entries.first?.mood
    }
}
