// MARK: - AI Insights ViewModel
// Генерує AI-підказки на основі останніх записів.
// Кешує результат у UserDefaults на 6 годин.
import Foundation
import Combine
import Factory

@MainActor
final class AIInsightsViewModel: ObservableObject {
    @Published var insight: AIInsight?
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Injected(\.diaryStore) private var diaryStore: DiaryStoreProtocol

    private let cacheKey     = "ai_insight_cache_v1"
    private let cacheInterval: TimeInterval = 6 * 3600  // 6 годин

    var isConfigured: Bool { GeminiService.shared.isConfigured }
    var isEnabled: Bool { UserDefaults.standard.bool(forKey: "ai_insights_enabled") }

    /// Дата останньої генерації (з кешу).
    var lastGeneratedAt: Date? { insight?.generatedAt }

    init() {
        // Читаємо дефолт вручну, бо @AppStorage недоступний тут
        if !UserDefaults.standard.bool(forKey: "ai_insights_enabled_set") {
            UserDefaults.standard.set(true, forKey: "ai_insights_enabled")
            UserDefaults.standard.set(true, forKey: "ai_insights_enabled_set")
        }
        loadCache()
    }

    // MARK: - Public

    func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        insight = nil
    }

    /// Завантажує з кешу; оновлює якщо кеш застарів або `force = true`.
    func loadIfNeeded(force: Bool = false) {
        guard isConfigured, isEnabled else { return }

        if !force, let cached = insight {
            let age = Date.now.timeIntervalSince(cached.generatedAt)
            if age < cacheInterval { return }
        }
        refresh()
    }

    func refresh() {
        guard !isLoading, isEnabled else { return }

        isLoading = true
        errorMessage = nil

        Task {
            defer { isLoading = false }
            do {
                let entries = try await diaryStore.fetchEntries()
                let recent  = Array(entries.prefix(10))
                guard !recent.isEmpty else { return }

                let prompt = buildPrompt(entries: recent)
                let raw    = try await GeminiService.shared.generate(prompt: prompt)
                let parsed = try parseInsight(from: raw)
                insight = parsed
                saveCache(parsed)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Prompt

    private func buildPrompt(entries: [DiaryEntry]) -> String {
        let fmt = DateFormatter()
        fmt.locale     = Locale(identifier: "uk_UA")
        fmt.dateFormat = "d MMMM yyyy"

        let entriesBlock = entries.map { e -> String in
            var lines = ["Дата: \(fmt.string(from: e.createdAt))"]
            if let m = e.mood    { lines.append("Настрій: \(m.label) \(m.emoji)") }
            if !e.tags.isEmpty   { lines.append("Теги: \(e.tags.joined(separator: ", "))") }
            let preview = String(e.text.prefix(400))
            if !preview.isEmpty  { lines.append("Текст: \(preview)") }
            return lines.joined(separator: "\n")
        }.joined(separator: "\n\n---\n\n")

        return """
        Ти — емпатичний асистент для особистого щоденника. Аналізуй записи та надавай корисні інсайти ВИКЛЮЧНО українською мовою.

        Останні записи щоденника користувача:

        \(entriesBlock)

        Завдання:
        1. Згенеруй одне персоналізоване запитання для роздумів. Звертайся на «ти». Спирайся на конкретні теми, події або настрої з записів (не загальні питання).
        2. Опиши один помічений емоційний паттерн або тенденцію (2–3 речення). Будь конкретним.

        Відповідай ТІЛЬКИ у форматі JSON (без markdown, без зайвих символів):
        {"question": "...", "pattern": "..."}
        """
    }

    // MARK: - Parse

    private func parseInsight(from raw: String) throws -> AIInsight {
        // Витягуємо перший JSON-об'єкт {…} з довільного тексту
        // (Gemini може додавати thinking-блоки або markdown навколо JSON)
        let jsonString = extractJSON(from: raw)

        guard
            let data     = jsonString.data(using: .utf8),
            let json     = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let question = json["question"] as? String, !question.isEmpty,
            let pattern  = json["pattern"]  as? String, !pattern.isEmpty
        else {
            throw ParseError.invalidFormat
        }

        return AIInsight(question: question, pattern: pattern)
    }

    /// Знаходить перший збалансований JSON-об'єкт {…} у рядку.
    private func extractJSON(from text: String) -> String {
        // Спочатку прибираємо markdown code-fences
        let stripped = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")

        // Знаходимо перший { і відповідний закриваючий }
        guard let start = stripped.firstIndex(of: "{") else { return stripped }
        var depth = 0
        var end = stripped.endIndex
        for idx in stripped[start...].indices {
            switch stripped[idx] {
            case "{": depth += 1
            case "}":
                depth -= 1
                if depth == 0 { end = stripped.index(after: idx); break }
            default: break
            }
            if depth == 0 { break }
        }
        return String(stripped[start..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Cache

    private func loadCache() {
        guard
            let data   = UserDefaults.standard.data(forKey: cacheKey),
            let cached = try? JSONDecoder().decode(AIInsight.self, from: data)
        else { return }
        insight = cached
    }

    private func saveCache(_ value: AIInsight) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: cacheKey)
    }

    private enum ParseError: LocalizedError {
        case invalidFormat
        var errorDescription: String? { "Не вдалося розібрати відповідь AI. Спробуйте ще раз." }
    }
}
