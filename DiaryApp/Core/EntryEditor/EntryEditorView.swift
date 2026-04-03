// MARK: - Entry Editor View
// Редактор запису з Markdown-форматуванням, настроєм і тегами.
import SwiftUI

struct EntryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: EntryEditorViewModel
    @FocusState private var isTextFocused: Bool
    @State private var showPreview: Bool

    init(entry: DiaryEntry?) {
        _viewModel = StateObject(wrappedValue: EntryEditorViewModel(entry: entry))
        _showPreview = State(initialValue: entry != nil)
    }

    var body: some View {
        ZStack {
            Color.diaryBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Navigation bar
                navBar

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Date
                        dateHeader

                        // Mood picker
                        if !showPreview { moodSection }

                        // Tags
                        if !showPreview { tagsSection }

                        // Text editor or preview
                        if showPreview {
                            markdownPreview
                        } else {
                            textEditorSection
                        }

                        Spacer().frame(height: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }

                // Markdown toolbar (when keyboard is visible, edit mode only)
                if isTextFocused && !showPreview {
                    markdownToolbar
                }
            }
        }
        .showError(viewModel: viewModel)
        .onAppear {
            viewModel.onDismiss = { dismiss() }
        }
    }

    // MARK: - Nav Bar
    private var navBar: some View {
        HStack {
            Button("Скасувати") { dismiss() }
                .font(.system(size: 16))
                .foregroundStyle(Color.diarySecondary)

            Spacer()

            Text(viewModel.isEditing ? "Редагувати" : "Новий запис")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.diaryPrimaryText)

            Spacer()

            HStack(spacing: 12) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showPreview.toggle()
                        if showPreview { isTextFocused = false }
                    }
                }) {
                    Image(systemName: showPreview ? "pencil" : "eye")
                        .font(.system(size: 16))
                        .foregroundStyle(showPreview ? Color.diaryPurple : Color.diarySecondary)
                }

                Button(action: viewModel.save) {
                    if viewModel.isSaving {
                        ProgressView().tint(Color.diaryPurple)
                    } else {
                        Text("Зберегти")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.diaryPurple)
                            .fixedSize()
                    }
                }
                .disabled(viewModel.isSaving)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.diaryBackground)
    }

    // MARK: - Date Header
    private var dateHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar")
                .font(.system(size: 14))
                .foregroundStyle(Color.diaryPurple)
            Text(viewModel.date.formatted(
                .dateTime
                    .weekday(.wide)
                    .day()
                    .month(.wide)
                    .year()
                    .hour()
                    .minute()
                    .locale(Locale(identifier: "uk_UA"))
            ).capitalized)
            .font(.system(size: 14))
            .foregroundStyle(Color.diarySecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.diaryCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Mood Section
    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Як ти почуваєшся?")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.diarySecondary)

            HStack(spacing: 0) {
                ForEach(MoodLevel.allCases) { mood in
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.mood = viewModel.mood == mood ? nil : mood
                        }
                    }) {
                        VStack(spacing: 4) {
                            ZStack {
                                if viewModel.mood == mood {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.diaryPurple.opacity(0.3))
                                        .frame(width: 52, height: 52)
                                }
                                Text(mood.emoji)
                                    .font(.system(size: 28))
                                    .scaleEffect(viewModel.mood == mood ? 1.1 : 1.0)
                            }
                            Text(mood.label)
                                .font(.system(size: 10))
                                .foregroundStyle(viewModel.mood == mood ? Color.diaryPurpleLight : Color.diaryTertiary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: - Tags Section
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Теги")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.diarySecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.tags, id: \.self) { tag in
                        HStack(spacing: 4) {
                            Text("#\(tag)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.diaryPurpleLight)
                            Button(action: { viewModel.removeTag(tag) }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color.diaryTertiary)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.diaryPurple.opacity(0.2))
                        .clipShape(Capsule())
                    }

                    // Add tag input
                    HStack(spacing: 4) {
                        TextField("+ Додати", text: $viewModel.tagInput)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.diaryPrimaryText)
                            .frame(maxWidth: viewModel.tagInput.isEmpty ? 70 : 120)
                            .onSubmit { viewModel.addTag() }
                        if !viewModel.tagInput.isEmpty {
                            Button(action: viewModel.addTag) {
                                Image(systemName: "return")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.diaryPurple)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.diaryCard)
                    .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Text Editor
    private var textEditorSection: some View {
        VStack(alignment: .trailing, spacing: 8) {
            ZStack(alignment: .topLeading) {
                if viewModel.text.isEmpty {
                    Text("Почни писати...")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.diaryTertiary)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $viewModel.text)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.diaryPrimaryText)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 200)
                    .focused($isTextFocused)
                    .onChange(of: viewModel.text) { _, _ in viewModel.updateWordCount() }
            }

            if viewModel.wordCount > 0 {
                Text("\(viewModel.wordCount) слів")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.diaryTertiary)
            }
        }
    }

    // MARK: - Markdown Preview
    private var markdownPreview: some View {
        Text(MarkdownRenderer.render(viewModel.text))
            .font(.system(size: 16))
            .foregroundStyle(Color.diaryPrimaryText)
            .frame(maxWidth: .infinity, minHeight: 200, alignment: .topLeading)
            .multilineTextAlignment(.leading)
            .padding(16)
            .background(Color.diaryCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Markdown Toolbar
    private var markdownToolbar: some View {
        HStack(spacing: 0) {
            ForEach(MarkdownFormat.allCases, id: \.self) { format in
                Button(action: { viewModel.applyFormat(format) }) {
                    Image(systemName: format.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.diarySecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
            }
            Button(action: { isTextFocused = false }) {
                Image(systemName: "keyboard.chevron.compact.down")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.diarySecondary)
                    .frame(width: 44, height: 44)
            }
        }
        .background(Color.diaryCard)
    }
}

#Preview {
    EntryEditorView(entry: nil)
}
