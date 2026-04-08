// MARK: - MockDiaryStore
// Тестові дані для SwiftUI Preview та розробки.
import Foundation

final class MockDiaryStore: DiaryStoreProtocol {

    private var entries: [DiaryEntry] = [
        DiaryEntry(
            id: "1",
            text: "Today was a **productive day**. Finished working on the project architecture. Feeling satisfied with what I've accomplished.",
            mood: .good,
            tags: ["work", "code"],
            createdAt: Calendar.current.date(byAdding: .hour, value: -2, to: .now)!,
            updatedAt: .now
        ),
        DiaryEntry(
            id: "2",
            text: "Thinking about the future. Did I choose the right path? Need to analyze my goals more and keep moving forward.",
            mood: .neutral,
            tags: ["reflections"],
            createdAt: Calendar.current.date(byAdding: .day, value: -1, to: .now)!,
            updatedAt: .now
        ),
        DiaryEntry(
            id: "3",
            text: "Morning run in the park. The weather was great, mood lifted. Should do this more regularly.",
            mood: .excellent,
            tags: ["sports", "nature"],
            createdAt: Calendar.current.date(byAdding: .day, value: -4, to: .now)!,
            updatedAt: .now
        ),
        DiaryEntry(
            id: "4",
            text: "Not very productive today. Got distracted by social media. Need to focus better.",
            mood: .bad,
            tags: ["self-reflection"],
            createdAt: Calendar.current.date(byAdding: .day, value: -7, to: .now)!,
            updatedAt: .now
        )
    ]

    func fetchEntries() async throws -> [DiaryEntry] { entries }

    func saveEntry(_ entry: DiaryEntry) async throws {
        if let idx = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[idx] = entry
        } else {
            entries.insert(entry, at: 0)
        }
    }

    func deleteEntry(id: String) async throws {
        entries.removeAll { $0.id == id }
    }

    func searchEntries(query: String) async throws -> [DiaryEntry] {
        guard !query.isEmpty else { return entries }
        return entries.filter {
            $0.text.localizedCaseInsensitiveContains(query) ||
            $0.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
}
