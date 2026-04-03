// MARK: - MockDiaryStore
// Тестові дані для SwiftUI Preview та розробки.
import Foundation

final class MockDiaryStore: DiaryStoreProtocol {

    private var entries: [DiaryEntry] = [
        DiaryEntry(
            id: "1",
            text: "Сьогодні був **продуктивний день**. Закінчив роботу над архітектурою проєкту. Відчуваю задоволення від зробленого.",
            mood: .good,
            tags: ["робота", "код"],
            createdAt: Calendar.current.date(byAdding: .hour, value: -2, to: .now)!,
            updatedAt: .now
        ),
        DiaryEntry(
            id: "2",
            text: "Думав про майбутнє. Чи правильний шлях я обрав? Треба більше аналізувати свої цілі та рухатись вперед.",
            mood: .neutral,
            tags: ["роздуми"],
            createdAt: Calendar.current.date(byAdding: .day, value: -1, to: .now)!,
            updatedAt: .now
        ),
        DiaryEntry(
            id: "3",
            text: "Ранкова пробіжка в парку. Погода чудова, настрій піднявся. Треба робити це регулярніше.",
            mood: .excellent,
            tags: ["спорт", "природа"],
            createdAt: Calendar.current.date(byAdding: .day, value: -4, to: .now)!,
            updatedAt: .now
        ),
        DiaryEntry(
            id: "4",
            text: "Не дуже продуктивно сьогодні. Відволікався на соцмережі. Потрібно краще фокусуватись.",
            mood: .bad,
            tags: ["саморефлексія"],
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
