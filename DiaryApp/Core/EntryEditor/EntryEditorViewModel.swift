// MARK: - Entry Editor ViewModel
import Foundation
import UIKit
import Factory
import Combine

@MainActor
final class EntryEditorViewModel: ObservableObject, ErrorDisplayable, AlertDisplayable {
    @Published var text: String = ""
    @Published var mood: MoodLevel?
    @Published var tags: [String] = []
    @Published var tagInput: String = ""
    @Published var attachments: [MediaAttachment] = []
    @Published var isSaving = false
    @Published var wordCount = 0
    @Published var error: Error?
    @Published var alert: AppAlert?
    @Published private(set) var allTags: [String] = []

    @Injected(\.diaryStore)  private var diaryStore: DiaryStoreProtocol
    @Injected(\.streakStore) private var streakStore: StreakStoreProtocol

    /// Теги для підказок: фільтр за введеним текстом, виключаємо вже додані
    var tagSuggestions: [String] {
        let query = tagInput.trimmingCharacters(in: .whitespaces).lowercased()
        let available = allTags.filter { !tags.contains($0) }
        guard !query.isEmpty else { return available }
        return available.filter { $0.lowercased().hasPrefix(query) }
    }

    // Фіксований ID протягом усього часу редагування
    private var entryID: String
    private let createdAt: Date
    private var autoSaveTimer: AnyCancellable?
    private var isDismissed = false

    var onDismiss: (() -> Void)?
    var date: Date { createdAt }
    var isEditing: Bool

    var entryId: String { entryID }

    init(entry: DiaryEntry?) {
        self.entryID   = entry?.id ?? UUID().uuidString
        self.createdAt = entry?.createdAt ?? .now
        self.isEditing = entry != nil
        if let entry {
            self.text        = entry.text
            self.mood        = entry.mood
            self.tags        = entry.tags
            self.attachments = entry.attachments
        }
        setupAutoSave()
        loadAllTags()
    }

    func save() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            dismiss()
            return
        }
        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                try await diaryStore.saveEntry(buildEntry())
                streakStore.recordEntry(for: .now)
                NotificationCenter.default.post(name: .diaryEntryUpdated, object: nil)
                dismiss()
            } catch {
                self.error = error
            }
        }
    }

    func addTag() {
        let tag = tagInput.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        guard !tag.isEmpty, !tags.contains(tag), tags.count < 10 else {
            tagInput = ""
            return
        }
        tags.append(tag)
        tagInput = ""
    }

    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }

    func updateWordCount() {
        wordCount = text.split { $0.isWhitespace || $0.isNewline }.count
    }

    // MARK: - Private

    private func loadAllTags() {
        Task {
            let entries = (try? await diaryStore.fetchEntries()) ?? []
            // Рахуємо частоту кожного тегу, щоб показати найпопулярніші першими
            var counts: [String: Int] = [:]
            entries.flatMap { $0.tags }.forEach { counts[$0, default: 0] += 1 }
            allTags = counts.sorted { $0.value > $1.value }.map { $0.key }
        }
    }

    // MARK: - Media

    func addPhotos(_ images: [UIImage]) {
        let eid = entryID
        Task {
            var added: [MediaAttachment] = []
            for image in images {
                if let att = MediaStore.shared.savePhoto(image, entryId: eid) { added.append(att) }
            }
            attachments.append(contentsOf: added)
        }
    }

    func addVideos(_ urls: [URL]) {
        let eid = entryID
        Task {
            var added: [MediaAttachment] = []
            for url in urls {
                if let att = MediaStore.shared.saveVideo(from: url, entryId: eid) { added.append(att) }
            }
            attachments.append(contentsOf: added)
        }
    }

    func addAudio(_ url: URL) {
        let eid = entryID
        Task {
            if let att = MediaStore.shared.saveAudio(from: url, entryId: eid) {
                attachments.append(att)
            }
        }
    }

    func removeAttachment(_ attachment: MediaAttachment) {
        attachments.removeAll { $0.id == attachment.id }
        let att = attachment
        let eid = entryID
        Task { MediaStore.shared.delete(att, entryId: eid) }
    }

    private func buildEntry() -> DiaryEntry {
        DiaryEntry(
            id:          entryID,
            text:        text,
            mood:        mood,
            tags:        tags,
            attachments: attachments,
            createdAt:   createdAt,
            updatedAt:   .now
        )
    }

    private func dismiss() {
        isDismissed = true
        autoSaveTimer?.cancel()
        autoSaveTimer = nil
        onDismiss?()
    }

    private func setupAutoSave() {
        autoSaveTimer = $text
            .debounce(for: .seconds(30), scheduler: RunLoop.main)
            .sink { [weak self] newText in
                guard let self, !isDismissed,
                      !newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                else { return }
                Task { try? await self.diaryStore.saveEntry(self.buildEntry()) }
            }
    }
}

enum MarkdownFormat: CaseIterable {
    case bold, italic, heading, list, quote

    var icon: String {
        switch self {
        case .bold:    return "bold"
        case .italic:  return "italic"
        case .heading: return "textformat.size.larger"
        case .list:    return "list.bullet"
        case .quote:   return "text.quote"
        }
    }

    var prefix: String {
        switch self {
        case .bold:    return "**"
        case .italic:  return "*"
        case .heading: return "\n## "
        case .list:    return "\n- "
        case .quote:   return "\n> "
        }
    }

    var suffix: String {
        switch self {
        case .bold:   return "**"
        case .italic: return "*"
        default:      return ""
        }
    }
}
