// MARK: - Search ViewModel
import Foundation
import Factory
import Combine

@MainActor
final class SearchViewModel: ObservableObject, ErrorDisplayable, AlertDisplayable {
    @Published var query = ""
    @Published var results: [DiaryEntry] = []
    @Published var isSearching = false
    @Published var selectedFilter: SearchFilter = .all
    @Published var error: Error?
    @Published var alert: AppAlert?

    @Injected(\.diaryStore) private var diaryStore: DiaryStoreProtocol
    private var cancellables = Set<AnyCancellable>()
    private var allEntries: [DiaryEntry] = []

    init() {
        $query
            .combineLatest($selectedFilter)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] query, filter in
                self?.applyFilter(query: query, filter: filter)
            }
            .store(in: &cancellables)
    }

    func load() {
        Task(operation: {
            do {
                allEntries = try await diaryStore.fetchEntries()
                applyFilter(query: query, filter: selectedFilter)
            } catch {
                self.error = error
            }
        })
    }

    private func applyFilter(query: String, filter: SearchFilter) {
        var filtered = allEntries

        if !query.isEmpty {
            filtered = filtered.filter {
                $0.text.localizedCaseInsensitiveContains(query) ||
                $0.tags.contains { $0.localizedCaseInsensitiveContains(query) }
            }
        }

        let calendar = Calendar.current
        switch filter {
        case .all:       break
        case .today:     filtered = filtered.filter { calendar.isDateInToday($0.createdAt) }
        case .thisWeek:  filtered = filtered.filter {
            calendar.isDate($0.createdAt, equalTo: .now, toGranularity: .weekOfYear)
        }
        case .mood(let mood):
            filtered = filtered.filter { $0.mood == mood }
        }

        results = filtered
    }
}

enum SearchFilter: Equatable {
    case all, today, thisWeek, mood(MoodLevel)

    var label: String {
        switch self {
        case .all:          return "Всі"
        case .today:        return "Сьогодні"
        case .thisWeek:     return "Цей тиждень"
        case .mood(let m):  return m.emoji
        }
    }
}
