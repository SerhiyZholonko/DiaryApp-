// MARK: - App Entry Point
import SwiftUI
import Factory
import FirebaseCore
import FirebaseMessaging
import FirebaseAuth
import FirebaseFirestore
import UserNotifications

#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        UNUserNotificationCenter.current().delegate = self
        #if !targetEnvironment(macCatalyst)
        Messaging.messaging().delegate = self
        #endif
        return true
    }

    // APNs токен → FCM (тільки iOS)
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        #if !targetEnvironment(macCatalyst)
        Messaging.messaging().apnsToken = deviceToken
        #endif
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("[FCM] APNs registration failed: \(error.localizedDescription)")
    }

    // Показуємо банер навіть коли додаток відкритий
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.banner, .sound, .badge]
    }

    static func clearBadge() {
        UIApplication.shared.applicationIconBadgeNumber = 0
        UNUserNotificationCenter.current().setBadgeCount(0) { _ in }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid)
            .setData(["badgeCount": 0], merge: true)
    }
}

#if !targetEnvironment(macCatalyst)
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        Task { await NotificationStore.shared.saveFCMToken(token) }
    }
}
#endif

@main
struct DiaryAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var theme = AppTheme()
    @StateObject private var languageManager = LanguageManager.shared
    @AppStorage("appearance_mode") private var appearanceMode = 0
    @Environment(\.scenePhase) private var scenePhase

    private var colorScheme: ColorScheme? {
        switch appearanceMode {
        case 1: return .dark
        case 2: return .light
        default: return nil
        }
    }

    init() { Container.shared.registerAll() }

    var body: some Scene {
        WindowGroup {
            AppStartingView()
                .environmentObject(theme)
                .environmentObject(languageManager)
                .tint(theme.accent)
                .preferredColorScheme(colorScheme)
                .onOpenURL { url in
                    #if canImport(GoogleSignIn)
                    GIDSignIn.sharedInstance.handle(url)
                    #endif
                }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { AppDelegate.clearBadge() }
        }
    }
}
