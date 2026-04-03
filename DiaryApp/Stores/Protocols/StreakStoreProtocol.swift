// MARK: - StreakStore Protocol
// Інтерфейс трекера серій.
import Foundation

protocol StreakStoreProtocol {
    var currentStreak: Int { get }
    var longestStreak: Int { get }
    var lastEntryDate: Date? { get }
    func recordEntry(for date: Date)
    func hasEntryToday() -> Bool
}
