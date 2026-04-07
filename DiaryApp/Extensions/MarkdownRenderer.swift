// MARK: - Markdown Renderer
// Рендерить підмножину Markdown у AttributedString для SwiftUI Text.
import SwiftUI

enum MarkdownRenderer {

    /// Повний рендер тексту (редактор-preview, перегляд запису).
    static func render(_ text: String) -> AttributedString {
        var result = AttributedString()
        let lines = text.components(separatedBy: "\n")
        for (i, line) in lines.enumerated() {
            if i > 0 { result += AttributedString("\n") }
            result += renderLine(line)
        }
        return result
    }

    /// Короткий рендер для карток (перші кілька рядків, без великих заголовків).
    static func preview(_ text: String, maxLines: Int = 3) -> AttributedString {
        let lines = text
            .components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .prefix(maxLines)
        var result = AttributedString()
        for (i, line) in lines.enumerated() {
            if i > 0 { result += AttributedString("\n") }
            result += renderLineCompact(line)
        }
        return result
    }

    // MARK: - Private

    private static func renderLine(_ line: String) -> AttributedString {
        if line.hasPrefix("### ") {
            var a = inlines(String(line.dropFirst(4)))
            a.font = .system(size: 16, weight: .semibold)
            return a
        }
        if line.hasPrefix("## ") {
            var a = inlines(String(line.dropFirst(3)))
            a.font = .system(size: 18, weight: .bold)
            return a
        }
        if line.hasPrefix("# ") {
            var a = inlines(String(line.dropFirst(2)))
            a.font = .system(size: 22, weight: .bold)
            return a
        }
        if line.hasPrefix("- ") || line.hasPrefix("* ") {
            return AttributedString("• ") + inlines(String(line.dropFirst(2)))
        }
        if line.hasPrefix("> ") {
            var prefix = AttributedString("│ ")
            prefix.foregroundColor = .secondary
            var body = inlines(String(line.dropFirst(2)))
            body.foregroundColor = .secondary
            return prefix + body
        }
        return inlines(line)
    }

    /// Компактний рядок для карток — прибирає синтаксис заголовків/списків,
    /// але зберігає жирний/курсив. Заголовки рендеряться напівжирним.
    private static func renderLineCompact(_ line: String) -> AttributedString {
        let stripped: String
        var isHeading = false
        if line.hasPrefix("### ") {
            stripped = String(line.dropFirst(4))
            isHeading = true
        } else if line.hasPrefix("## ") {
            stripped = String(line.dropFirst(3))
            isHeading = true
        } else if line.hasPrefix("# ") {
            stripped = String(line.dropFirst(2))
            isHeading = true
        } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
            stripped = "• " + String(line.dropFirst(2))
        } else if line.hasPrefix("> ") {
            stripped = String(line.dropFirst(2))
        } else {
            stripped = line
        }
        var result = inlines(stripped)
        if isHeading {
            result.font = .system(size: 15, weight: .semibold)
        }
        return result
    }

    private static func inlines(_ text: String) -> AttributedString {
        (try? AttributedString(
            markdown: text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(text)
    }
}
