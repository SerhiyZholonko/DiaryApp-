// MARK: - AuthStore
// Google Sign-In через Firebase Auth.
//
// ⚠️  ПЕРЕД ВИКОРИСТАННЯМ додайте пакет:
//     File → Add Package Dependencies →
//     https://github.com/google/GoogleSignIn-iOS
//
// Також у Info.plist додайте URL Scheme = REVERSED_CLIENT_ID з GoogleService-Info.plist
import Foundation
import UIKit
import FirebaseAuth
import FirebaseCore

#if canImport(GoogleSignIn)
import GoogleSignIn

final class AuthStore: AuthStoreProtocol {

    func signInWithGoogle(presenting viewController: UIViewController) async throws -> AppUser {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthError.missingClientID
        }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
        let user   = result.user
        guard let idToken = user.idToken?.tokenString else {
            throw AuthError.missingToken
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: user.accessToken.tokenString
        )
        let authResult   = try await Auth.auth().signIn(with: credential)
        let firebaseUser = authResult.user

        return AppUser(
            id: firebaseUser.uid,
            displayName: firebaseUser.displayName ?? "Користувач",
            email: firebaseUser.email ?? "",
            photoURL: firebaseUser.photoURL
        )
    }

    func signOut() throws {
        GIDSignIn.sharedInstance.signOut()
        try Auth.auth().signOut()
    }

    func currentUser() -> AppUser? {
        guard let user = Auth.auth().currentUser else { return nil }
        return AppUser(
            id: user.uid,
            displayName: user.displayName ?? "Користувач",
            email: user.email ?? "",
            photoURL: user.photoURL
        )
    }
}

#else

// Stub — замінити після додавання GoogleSignIn-iOS пакету
final class AuthStore: AuthStoreProtocol {

    func signInWithGoogle(presenting viewController: UIViewController) async throws -> AppUser {
        // Для тестування повертає тимчасового користувача
        // Додайте пакет GoogleSignIn-iOS для реального входу
        try await Task.sleep(for: .seconds(1))
        return AppUser(
            id: UUID().uuidString,
            displayName: "Тестовий Користувач",
            email: "test@diary.app",
            photoURL: nil
        )
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    func currentUser() -> AppUser? {
        guard let user = Auth.auth().currentUser else { return nil }
        return AppUser(
            id: user.uid,
            displayName: user.displayName ?? "Користувач",
            email: user.email ?? "",
            photoURL: user.photoURL
        )
    }
}

#endif

enum AuthError: LocalizedError {
    case missingClientID
    case missingToken

    var errorDescription: String? {
        switch self {
        case .missingClientID: return "Відсутній Client ID Firebase"
        case .missingToken:    return "Не вдалося отримати токен Google"
        }
    }
}
