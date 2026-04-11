// MARK: - NotificationStore
// Push-нагадування через Firebase Cloud Messaging.
// Зберігає FCM-токен + час нагадування (UTC) у Firestore.
// Cloud Function `sendDailyReminders` запускається щохвилини і шле FCM.
// На macOS — тільки локальні нагадування (APNs/FCM недоступні).
import Foundation
import UserNotifications
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging

#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class NotificationStore {

    static let shared = NotificationStore()
    private init() {}

    private var db: Firestore { Firestore.firestore() }
    private var uid: String? { Auth.auth().currentUser?.uid }

    // MARK: - Permission

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        if granted {
            #if canImport(UIKit) && !targetEnvironment(macCatalyst)
            UIApplication.shared.registerForRemoteNotifications()
            #endif
        }
        return granted
    }

    // MARK: - Schedule / Cancel

    func scheduleDailyReminder(at hour: Int, minute: Int) {
        #if targetEnvironment(macCatalyst) || os(macOS)
        scheduleLocalReminder(hour: hour, minute: minute)
        #else
        scheduleRemoteReminder(hour: hour, minute: minute)
        #endif
    }

    func cancelReminder() {
        #if targetEnvironment(macCatalyst) || os(macOS)
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["diary_daily_reminder"])
        #else
        guard let uid else { return }
        Task {
            try? await db.collection("users").document(uid).setData(
                ["reminderEnabled": false], merge: true)
        }
        #endif
    }

    // MARK: - FCM Token (iOS only)

    func saveFCMToken(_ token: String) {
        guard let uid else { return }
        Task {
            // merge: true — оновлює fcmToken незалежно від інших полів
            try? await db.collection("users").document(uid).setData(
                ["fcmToken": token], merge: true)
        }
    }

    // MARK: - Private

    /// iOS: зберігає в Firestore, Cloud Function шле FCM push.
    private func scheduleRemoteReminder(hour: Int, minute: Int) {
        guard let uid else { return }
        let (utcHour, utcMinute) = toUTC(hour: hour, minute: minute)
        let fcmToken = Messaging.messaging().fcmToken ?? ""
        let lang = LanguageManager.shared.language.rawValue
        Task {
            try? await db.collection("users").document(uid).setData([
                "reminderEnabled": true,
                "reminderHour":    utcHour,
                "reminderMinute":  utcMinute,
                "fcmToken":        fcmToken,
                "language":        lang
            ], merge: true)
        }
    }

    /// macOS: локальне нагадування через UNCalendarNotificationTrigger.
    private func scheduleLocalReminder(hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["diary_daily_reminder"])

        let content = UNMutableNotificationContent()
        let L: (String, String) -> String = LanguageManager.shared.l
        content.title = L("Time to write your day 📖", "Час записати свій день 📖")
        content.body  = L("How was your day? Write your thoughts in the diary.",
                          "Як пройшов твій день? Запиши свої думки у щоденнику.")
        content.sound = .default

        var components  = DateComponents()
        components.hour   = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "diary_daily_reminder",
                                            content: content, trigger: trigger)
        center.add(request)
    }

    private func toUTC(hour: Int, minute: Int) -> (hour: Int, minute: Int) {
        var cal = Calendar.current
        cal.timeZone = .current
        var comps = cal.dateComponents([.year, .month, .day], from: Date())
        comps.hour = hour
        comps.minute = minute
        let localDate = cal.date(from: comps) ?? Date()
        var utcCal = Calendar(identifier: .gregorian)
        utcCal.timeZone = TimeZone(identifier: "UTC")!
        return (utcCal.component(.hour, from: localDate),
                utcCal.component(.minute, from: localDate))
    }
}
