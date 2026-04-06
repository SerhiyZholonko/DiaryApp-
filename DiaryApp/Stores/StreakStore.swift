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

    /// Перераховує поточну і найдовшу серію з реальних дат записів.
    /// Викликається після завантаження записів з Firestore, щоб відновити
    /// коректні значення на новому пристрої або при першому вході.
    func recalculate(from dates: [Date]) {
        guard !dates.isEmpty else { return }

        let calendar = Calendar.current

        // Унікальні дні (без часу), відсортовані за зростанням
        let days = Array(
            Set(dates.map { calendar.startOfDay(for: $0) })
        ).sorted()

        // Підраховуємо найдовшу серію
        var longest = 1
        var run     = 1
        for i in 1 ..< days.count {
            let diff = calendar.dateComponents([.day], from: days[i - 1], to: days[i]).day ?? 0
            run = (diff == 1) ? run + 1 : 1
            if run > longest { longest = run }
        }

        // Підраховуємо поточну серію (йдемо назад від сьогодні або вчора)
        let today     = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        var current   = 0

        if let last = days.last, last == today || last == yesterday {
            current = 1
            var cursor = last
            for day in days.dropLast().reversed() {
                let prev = calendar.date(byAdding: .day, value: -1, to: cursor)!
                if day == prev { current += 1; cursor = day } else { break }
            }
        }

        setCurrentStreak(current)
        if longest > longestStreak { setLongestStreak(longest) }
        if let last = days.last { setLastEntryDate(last) }
    }
}
