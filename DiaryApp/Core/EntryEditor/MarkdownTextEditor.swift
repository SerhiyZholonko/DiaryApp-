// MARK: - Markdown Text Editor
// UIViewRepresentable над UITextView — дає доступ до selectedRange для форматування.
import SwiftUI
import UIKit
import Combine

// MARK: - Controller

final class MarkdownEditorController: ObservableObject {
    fileprivate weak var textView: UITextView?

    /// Обертає виділений текст маркерами, або вставляє prefix+suffix і ставить курсор між ними.
    func applyFormat(prefix: String, suffix: String) {
        guard let tv = textView else { return }
        let full = tv.text ?? ""
        let sel = tv.selectedRange

        let replacement: String
        let newCursor: Int

        if sel.length > 0, let range = Range(sel, in: full) {
            let selected = String(full[range])
            replacement = prefix + selected + suffix
            newCursor = sel.location + replacement.utf16.count
        } else {
            replacement = prefix + suffix
            newCursor = sel.location + prefix.utf16.count
        }

        tv.text = (full as NSString).replacingCharacters(in: sel, with: replacement)
        tv.selectedRange = NSRange(location: newCursor, length: 0)
        tv.delegate?.textViewDidChange?(tv)
    }

    func resignFocus() {
        textView?.resignFirstResponder()
    }
}

// MARK: - View

struct MarkdownTextEditor: UIViewRepresentable {
    @Binding var text: String
    let controller: MarkdownEditorController
    var onFocusChange: (Bool) -> Void = { _ in }
    var onTextChange: () -> Void = {}

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onFocusChange: onFocusChange, onTextChange: onTextChange)
    }

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.delegate = context.coordinator
        tv.font = .systemFont(ofSize: 16)
        tv.backgroundColor = .clear
        tv.textColor = UIColor(Color.diaryPrimaryText)
        tv.text = text
        tv.isScrollEnabled = false
        tv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        controller.textView = tv
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        controller.textView = uiView
        // Оновлюємо текст тільки якщо зміна прийшла зовні (напр. автозбереження)
        if uiView.text != text {
            uiView.text = text
        }
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String
        var onFocusChange: (Bool) -> Void
        var onTextChange: () -> Void

        init(
            text: Binding<String>,
            onFocusChange: @escaping (Bool) -> Void,
            onTextChange: @escaping () -> Void
        ) {
            _text = text
            self.onFocusChange = onFocusChange
            self.onTextChange = onTextChange
        }

        func textViewDidChange(_ textView: UITextView) {
            text = textView.text
            onTextChange()
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            onFocusChange(true)
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            onFocusChange(false)
        }
    }
}
