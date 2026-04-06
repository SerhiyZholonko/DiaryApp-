// MARK: - Speech Transcriber
// Транскрибує аудіофайл у текст через Apple Speech framework.
// Основна мова — uk-UA; fallback на поточний locale пристрою.
import Speech
import Foundation

final class SpeechTranscriber {
    static let shared = SpeechTranscriber()
    private init() {}

    /// Транскрибує аудіофайл за URL. Кидає `TranscriptionError` або системну помилку.
    func transcribe(url: URL) async throws -> String {
        try await requestAuthorization()

        let preferredLocale = Locale(identifier: "uk-UA")
        let recognizer: SFSpeechRecognizer? =
            SFSpeechRecognizer(locale: preferredLocale)?.isAvailable == true
                ? SFSpeechRecognizer(locale: preferredLocale)
                : SFSpeechRecognizer()

        guard let recognizer, recognizer.isAvailable else {
            throw TranscriptionError.unavailable
        }

        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false

        return try await withCheckedThrowingContinuation { continuation in
            var resumed = false
            recognizer.recognitionTask(with: request) { result, error in
                guard !resumed else { return }
                if let error {
                    resumed = true
                    continuation.resume(throwing: error)
                } else if let result, result.isFinal {
                    resumed = true
                    let text = result.bestTranscription.formattedString
                    continuation.resume(returning: text.isEmpty ? "" : text)
                }
            }
        }
    }

    // MARK: - Permission

    private func requestAuthorization() async throws {
        let status = SFSpeechRecognizer.authorizationStatus()
        guard status != .authorized else { return }
        guard status == .notDetermined else { throw TranscriptionError.permissionDenied }

        return try await withCheckedThrowingContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { newStatus in
                if newStatus == .authorized {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: TranscriptionError.permissionDenied)
                }
            }
        }
    }

    // MARK: - Errors

    enum TranscriptionError: LocalizedError {
        case unavailable
        case permissionDenied
        case emptyResult

        var errorDescription: String? {
            switch self {
            case .unavailable:
                return "Розпізнавання мови недоступне на цьому пристрої"
            case .permissionDenied:
                return "Немає дозволу на розпізнавання мови. Увімкніть у Налаштуваннях → Конфіденційність → Розпізнавання мовлення."
            case .emptyResult:
                return "Не вдалося розпізнати текст у записі"
            }
        }
    }
}
