// MARK: - Settings ViewModel
import Foundation
import Combine
import Factory
import SwiftUI

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
        switch minutes {
        case 0:  return "Одразу"
        case 1:  return "1 хвилина"
        case 5:  return "5 хвилин"
        case 15: return "15 хвилин"
        default: return "\(minutes) хв"
        }
    }
}
