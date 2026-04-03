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
        var error: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return true // якщо біометрика недоступна — пропускаємо
        }
        return try await ctx.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: "Підтвердіть вашу особистість для доступу до щоденника"
        )
    }
}
