// MARK: - App Entry Point
import SwiftUI
import Factory
import FirebaseCore

#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct DiaryAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var theme = AppTheme()
    @StateObject private var languageManager = LanguageManager.shared
    @AppStorage("appearance_mode") private var appearanceMode = 0

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
    }
}
