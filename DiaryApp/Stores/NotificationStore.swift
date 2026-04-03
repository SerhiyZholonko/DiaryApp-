// MARK: - NotificationStore
// Локальні push-нагадування через UNUserNotificationCenter.
import Foundation
import UserNotifications

final class NotificationStore {

    static let shared = NotificationStore()
    private init() {}

    private let notificationID = "diary_daily_reminder"

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        return granted ?? false
    }

    func scheduleDailyReminder(at hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [notificationID])

        let content = UNMutableNotificationContent()
        content.title = "Час записати день 📖"
        content.body  = "Як пройшов твій день? Зафіксуй думки у щоденнику."
        content.sound = .default

        var components        = DateComponents()
        components.hour       = hour
        components.minute     = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)
        center.add(request)
    }

    func cancelReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])
    }
}
