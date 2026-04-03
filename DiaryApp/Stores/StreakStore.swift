// MARK: - StreakStore
// Трекер серій записів. Зберігає в UserDefaults.
import Foundation

final class StreakStore: StreakStoreProtocol {

    private let currentKey  = "streak_current"
    private let longestKey  = "streak_longest"
    private let lastDateKey = "streak_last_date"
    private let defaults    = UserDefaults.standard

    var currentStreak: Int { defaults.integer(forKey: currentKey) }
    var longestStreak: Int { defaults.integer(forKey: longestKey) }
    var lastEntryDate: Date? { defaults.object(forKey: lastDateKey) as? Date }

    private func setCurrentStreak(_ val: Int) { defaults.set(val, forKey: currentKey) }
    private func setLongestStreak(_ val: Int) { defaults.set(val, forKey: longestKey) }
    private func setLastEntryDate(_ val: Date) { defaults.set(val, forKey: lastDateKey) }

    func hasEntryToday() -> Bool {
        guard let last = lastEntryDate else { return false }
        return Calendar.current.isDateInToday(last)
    }

    func recordEntry(for date: Date) {
        let calendar = Calendar.current
        guard let last = lastEntryDate else {
            setCurrentStreak(1)
            setLongestStreak(1)
            setLastEntryDate(date)
            return
        }
        if calendar.isDateInToday(last) { return }

        let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: date))!
        let lastDay   = calendar.startOfDay(for: last)

        let newStreak = (lastDay == yesterday) ? currentStreak + 1 : 1
        setCurrentStreak(newStreak)
        if newStreak > longestStreak { setLongestStreak(newStreak) }
        setLastEntryDate(date)
    }
}
