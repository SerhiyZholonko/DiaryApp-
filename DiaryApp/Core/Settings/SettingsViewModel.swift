// MARK: - Settings ViewModel
import Foundation
import Combine
import Factory
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class SettingsViewModel: ObservableObject, ErrorDisplayable, AlertDisplayable {
    @Published var error: Error?
    @Published var alert: AppAlert?

    // Security
    @AppStorage("security_faceID_enabled") var faceIDEnabled = false
    @AppStorage("security_auto_lock_minutes") var autoLockMinutes = 1

    // Reminders
    @AppStorage("reminder_enabled")  var reminderEnabled = false
    @AppStorage("reminder_hour")     var reminderHour    = 21
    @AppStorage("reminder_minute")   var reminderMinute  = 0
    @AppStorage("streak_goal")       var streakGoal      = 30

    // Appearance
    @AppStorage("appearance_mode")   var appearanceMode  = 0 // 0=system, 1=dark, 2=light

    // AI
    @AppStorage("ai_insights_enabled") var aiInsightsEnabled = true

    @Injected(\.authStore) private var authStore: AuthStoreProtocol

    var currentUser: AppUser? { AppSession.shared.currentUser }

    var reminderTime: Date {
        get {
            var components = DateComponents()
            components.hour   = reminderHour
            components.minute = reminderMinute
            return Calendar.current.date(from: components) ?? .now
        }
        set {
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            reminderHour   = components.hour   ?? 21
            reminderMinute = components.minute ?? 0
            if reminderEnabled { scheduleReminder() }
        }
    }

    func toggleFaceID() {
        if faceIDEnabled {
            faceIDEnabled = false
        } else {
            Task(operation: {
                let ok = (try? await SecurityStore.shared.authenticate()) ?? false
                if ok { faceIDEnabled = true }
            })
        }
    }

    func toggleReminder() {
        reminderEnabled.toggle()
        Task(operation: {
            if reminderEnabled {
                let granted = await NotificationStore.shared.requestPermission()
                if granted { scheduleReminder() } else { reminderEnabled = false }
            } else {
                NotificationStore.shared.cancelReminder()
            }
        })
    }

    private func scheduleReminder() {
        NotificationStore.shared.scheduleDailyReminder(at: reminderHour, minute: reminderMinute)
    }

    /// Завантажує час нагадування з Firestore і синхронізує з локальним AppStorage.
    /// Викликається при відкритті Settings.
    func syncReminderFromCloud() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Task {
            guard let data = try? await Firestore.firestore()
                .collection("users").document(uid).getDocument().data(),
                  let enabled = data["reminderEnabled"] as? Bool,
                  let utcHour = data["reminderHour"] as? Int,
                  let utcMin  = data["reminderMinute"] as? Int
            else { return }

            let local = utcToLocal(hour: utcHour, minute: utcMin)
            reminderEnabled = enabled
            reminderHour    = local.hour
            reminderMinute  = local.minute
        }
    }

    private func utcToLocal(hour: Int, minute: Int) -> (hour: Int, minute: Int) {
        var utcCal = Calendar(identifier: .gregorian)
        utcCal.timeZone = TimeZone(identifier: "UTC")!
        var comps = utcCal.dateComponents([.year, .month, .day], from: Date())
        comps.hour = hour
        comps.minute = minute
        let utcDate = utcCal.date(from: comps) ?? Date()
        let localCal = Calendar.current
        return (localCal.component(.hour, from: utcDate),
                localCal.component(.minute, from: utcDate))
    }

    func signOut(completion: @escaping () -> Void) {
        do {
            try authStore.signOut()
            AppSession.shared.currentUser = nil
            completion()
        } catch {
            self.error = error
        }
    }

    let autoLockOptions = [1, 5, 15, 0]  // 0 = одразу

    func autoLockLabel(_ minutes: Int) -> String {
        let L: (String, String) -> String = LanguageManager.shared.l
        switch minutes {
        case 0:  return L("Immediately", "Одразу")
        case 1:  return L("1 minute", "1 хвилина")
        case 5:  return L("5 minutes", "5 хвилин")
        case 15: return L("15 minutes", "15 хвилин")
        default: return "\(minutes) \(L("min", "хв"))"
        }
    }
}
