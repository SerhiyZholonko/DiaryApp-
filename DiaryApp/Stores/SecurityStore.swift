// MARK: - SecurityStore
// Автентифікація через FaceID / TouchID.
import Foundation
import LocalAuthentication

final class SecurityStore {

    static let shared = SecurityStore()
    private init() {}

    private let isEnabledKey   = "security_faceID_enabled"
    private let autoLockKey    = "security_auto_lock_minutes"

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: isEnabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: isEnabledKey) }
    }

    var autoLockMinutes: Int {
        get {
            let val = UserDefaults.standard.integer(forKey: autoLockKey)
            return val == 0 ? 1 : val
        }
        set { UserDefaults.standard.set(newValue, forKey: autoLockKey) }
    }

    var biometryType: LABiometryType {
        let ctx = LAContext()
        _ = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return ctx.biometryType
    }

    func authenticate() async throws -> Bool {
        let ctx = LAContext()
        var nsError: NSError?
        let reason = LanguageManager.shared.l("Confirm your identity to access your diary",
                                               "Підтвердь свою особистість для доступу до щоденника")

        if ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &nsError) {
            // Спробуємо Face ID / Touch ID
            do {
                return try await ctx.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
            } catch let laError as LAError {
                // Якщо користувач скасував — кидаємо далі, щоб кнопка залишалась
                if laError.code == .userCancel { throw laError }
                // При lockout або іншій помилці — падаємо на пасскод нижче
            }
        }

        // Fallback: пасскод (якщо Face ID недоступний або заблокований)
        let fallbackCtx = LAContext()
        guard fallbackCtx.canEvaluatePolicy(.deviceOwnerAuthentication, error: &nsError) else {
            return true // немає жодного методу авторизації — пропускаємо
        }
        return try await fallbackCtx.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
    }
}
