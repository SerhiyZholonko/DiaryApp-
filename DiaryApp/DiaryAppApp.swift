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
    @AppStorage("accent_color_idx") var accentColorIdx = 0
    @AppStorage("appearance_mode")  var appearanceMode = 0 // 0=system, 1=dark, 2=light

    private let accentColors: [Color] = [
        Color(hex: "#7B61FF"),
        Color(hex: "#00BCD4"),
        Color(hex: "#F44336"),
        Color(hex: "#4CAF50"),
        Color(hex: "#FFD166")
    ]

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
                .tint(accentColors[accentColorIdx])
                .preferredColorScheme(colorScheme)
                .onOpenURL { url in
                    #if canImport(GoogleSignIn)
                    GIDSignIn.sharedInstance.handle(url)
                    #endif
                }
        }
    }
}
