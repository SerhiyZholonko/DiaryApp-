// MARK: - Gemini Service
// Викликає Firebase Cloud Function `generateAIInsight` як проксі до Gemini.
// API ключ зберігається в Google Cloud Secret Manager — клієнт його не знає.
import Foundation
import FirebaseAuth

final class GeminiService {
    static let shared = GeminiService()
    private init() {}

    private let functionURL =
        "https://us-central1-diaryapp-b21a1.cloudfunctions.net/generateAIInsight"

    var isConfigured: Bool { true }

    // MARK: - Generate

    func generate(prompt: String) async throws -> String {
        guard let user = Auth.auth().currentUser else {
            throw GeminiError.unauthenticated
        }

        // Отримуємо свіжий Firebase ID Token (авто-оновлюється якщо протермінований)
        let idToken = try await user.getIDToken(forcingRefresh: false)

        guard let url = URL(string: functionURL) else {
            throw GeminiError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        // Простий REST-формат: { "prompt": "..." }
        request.httpBody = try JSONSerialization.data(withJSONObject: ["prompt": prompt])

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }

        // Будь-яка помилка — парсимо поле "error" з відповіді
        guard http.statusCode == 200 else {
            if let json    = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = json["error"] as? String {
                throw GeminiError.functionError(message)
            }
            throw GeminiError.serverError(http.statusCode)
        }

        // Успіх — парсимо поле "text"
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let text = json["text"] as? String
        else {
            throw GeminiError.invalidResponse
        }

        return text
    }

    // MARK: - Errors

    enum GeminiError: LocalizedError {
        case unauthenticated
        case invalidResponse
        case serverError(Int)
        case functionError(String)

        var errorDescription: String? {
            switch self {
            case .unauthenticated:
                return LanguageManager.shared.l("Authorization required for AI tips.", "Потрібна авторизація для AI підказок.")
            case .invalidResponse:
                return LanguageManager.shared.l("Invalid AI service response.", "Невірна відповідь від AI сервісу.")
            case .serverError(let code):
                return LanguageManager.shared.l("Server error (\(code)).", "Помилка сервера (\(code)).")
            case .functionError(let msg):
                return msg
            }
        }
    }
}
