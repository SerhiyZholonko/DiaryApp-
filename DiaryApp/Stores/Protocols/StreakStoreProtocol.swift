// MARK: - StreakStore Protocol
// Інтерфейс трекера серій.
import Foundation

protocol StreakStoreProtocol {
    var currentStreak: Int { get }
    var longestStreak: Int { get }
    var lastEntryDate: Date? { get }
    func recordEntry(for date: Date)
    func hasEntryToday() -> Bool
    /// Перераховує серію з реальних дат записів (викликати після завантаження з Firestore).
    func recalculate(from dates: [Date])
}
