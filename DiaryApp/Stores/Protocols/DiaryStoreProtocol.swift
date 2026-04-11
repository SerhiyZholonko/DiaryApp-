// MARK: - DiaryStore Protocol
// Інтерфейс доступу до записів щоденника.
import Foundation

protocol DiaryStoreProtocol {
    func fetchEntries() async throws -> [DiaryEntry]
    func fetchEntries(limit: Int, after cursor: AnyObject?) async throws -> (entries: [DiaryEntry], cursor: AnyObject?)
    func saveEntry(_ entry: DiaryEntry) async throws
    func deleteEntry(id: String) async throws
    func searchEntries(query: String) async throws -> [DiaryEntry]
}
