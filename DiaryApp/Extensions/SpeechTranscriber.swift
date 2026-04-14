// MARK: - Speech Transcriber
// Транскрибує аудіофайл у текст через Apple Speech framework.
// Locale береться з мови застосунку; fallback на Locale.current, потім на системний розпізнавач.
import Speech
import Foundation

final class SpeechTranscriber {
    static let shared = SpeechTranscriber()
    private init() {}

    /// Транскрибує аудіофайл за URL. `locale` — мова розпізнавання (за замовчуванням — поточний locale пристрою).
    func transcribe(url: URL, locale: Locale = .current) async throws -> String {
        try await requestAuthorization()

        let recognizer: SFSpeechRecognizer? = {
            if let r = SFSpeechRecognizer(locale: locale), r.isAvailable { return r }
            if let r = SFSpeechRecognizer(locale: .current), r.isAvailable { return r }
            return SFSpeechRecognizer()
        }()

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
                return "Speech recognition is unavailable on this device"
            case .permissionDenied:
                return "No speech recognition permission. Enable it in Settings → Privacy → Speech Recognition."
            case .emptyResult:
                return "Could not recognize text in the recording"
            }
        }
    }
}
