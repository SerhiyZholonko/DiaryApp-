// MARK: - AuthStore
// Google Sign-In + Sign In with Apple через Firebase Auth.
import Foundation
import UIKit
import FirebaseAuth
import FirebaseCore
import AuthenticationServices
import CryptoKit

#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

final class AuthStore: AuthStoreProtocol {

    // MARK: - Google

    func signInWithGoogle(presenting viewController: UIViewController) async throws -> AppUser {
#if canImport(GoogleSignIn)
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
#else
        try await Task.sleep(for: .seconds(1))
        return AppUser(id: UUID().uuidString, displayName: "Тестовий Користувач",
                       email: "test@diary.app", photoURL: nil)
#endif
    }

    // MARK: - Apple

    func signInWithApple() async throws -> AppUser {
        let nonce     = randomNonceString()
        let hashedNonce = sha256(nonce)

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = hashedNonce

        let appleCredential: ASAuthorizationAppleIDCredential =
            try await withCheckedThrowingContinuation { continuation in
                let delegate = AppleSignInDelegate(continuation: continuation)
                let controller = ASAuthorizationController(authorizationRequests: [request])
                controller.delegate = delegate
                controller.presentationContextProvider = delegate
                // Утримуємо делегат живим на час запиту
                objc_setAssociatedObject(controller, &AppleSignInDelegate.associatedKey,
                                         delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                controller.performRequests()
            }

        guard
            let tokenData  = appleCredential.identityToken,
            let idToken    = String(data: tokenData, encoding: .utf8)
        else { throw AuthError.missingToken }

        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: idToken,
            rawNonce: nonce,
            fullName: appleCredential.fullName
        )

        let authResult   = try await Auth.auth().signIn(with: firebaseCredential)
        let firebaseUser = authResult.user

        // Apple надає ім'я лише при першому вході
        var displayName = firebaseUser.displayName ?? ""
        if displayName.isEmpty, let fullName = appleCredential.fullName {
            displayName = PersonNameComponentsFormatter().string(from: fullName)
        }
        if displayName.isEmpty { displayName = "Користувач" }

        return AppUser(
            id: firebaseUser.uid,
            displayName: displayName,
            email: firebaseUser.email ?? appleCredential.email ?? "",
            photoURL: firebaseUser.photoURL
        )
    }

    // MARK: - Common

    func signOut() throws {
#if canImport(GoogleSignIn)
        GIDSignIn.sharedInstance.signOut()
#endif
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

    // MARK: - Nonce helpers

    private func randomNonceString(length: Int = 32) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(bytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let data   = Data(input.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Apple Sign-In Delegate

private final class AppleSignInDelegate: NSObject,
    ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding
{
    static var associatedKey = "AppleSignInDelegateKey"
    private let continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>

    init(continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>) {
        self.continuation = continuation
    }

    func authorizationController(controller: ASAuthorizationController,
                                  didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            continuation.resume(throwing: AuthError.missingToken)
            return
        }
        continuation.resume(returning: credential)
    }

    func authorizationController(controller: ASAuthorizationController,
                                  didCompleteWithError error: Error) {
        continuation.resume(throwing: error)
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? UIWindow()
    }
}

// MARK: - Errors

enum AuthError: LocalizedError {
    case missingClientID
    case missingToken

    var errorDescription: String? {
        switch self {
        case .missingClientID: return "Відсутній Client ID Firebase"
        case .missingToken:    return "Не вдалося отримати токен"
        }
    }
}
