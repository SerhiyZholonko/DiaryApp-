// MARK: - Entry Editor View
// Редактор запису з Markdown-форматуванням, настроєм і тегами.
import SwiftUI

struct EntryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var theme: AppTheme
    @StateObject private var viewModel: EntryEditorViewModel
    @State private var isTextFocused = false
    @StateObject private var editorController = MarkdownEditorController()
    @State private var showPreview: Bool

    init(entry: DiaryEntry?) {
        _viewModel = StateObject(wrappedValue: EntryEditorViewModel(entry: entry))
        _showPreview = State(initialValue: entry != nil)
    }

    var body: some View {
        ZStack {
            Color.diaryBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                navBar

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        dateHeader

                        if !showPreview { moodSection }
                        if !showPreview { tagsSection }

                        // Edit / Preview toggle
                        editPreviewToggle

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

            Button(action: viewModel.save) {
                if viewModel.isSaving {
                    ProgressView().tint(theme.accent)
                } else {
                    Text("Зберегти")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(theme.accent)
                        .fixedSize()
                }
            }
            .disabled(viewModel.isSaving)
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
                .foregroundStyle(theme.accent)
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

    // MARK: - Edit / Preview Toggle
    private var editPreviewToggle: some View {
        HStack(spacing: 0) {
            toggleSegment(title: "Редагувати", icon: "pencil", isActive: !showPreview) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showPreview = false
                }
            }
            toggleSegment(title: "Перегляд", icon: "eye", isActive: showPreview) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showPreview = true
                    isTextFocused = false
                    editorController.resignFocus()
                }
            }
        }
        .background(Color.diaryCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func toggleSegment(title: String, icon: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(isActive ? theme.accent : Color.diarySecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isActive ? theme.accent.opacity(0.12) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(3)
        }
        .buttonStyle(.plain)
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
                                        .fill(theme.accent.opacity(0.3))
                                        .frame(width: 52, height: 52)
                                }
                                Text(mood.emoji)
                                    .font(.system(size: 28))
                                    .scaleEffect(viewModel.mood == mood ? 1.1 : 1.0)
                            }
                            Text(mood.label)
                                .font(.system(size: 10))
                                .foregroundStyle(viewModel.mood == mood ? theme.accentLight : Color.diaryTertiary)
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

            // Додані теги + поле вводу
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.tags, id: \.self) { tag in
                        HStack(spacing: 4) {
                            Text("#\(tag)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(theme.accentLight)
                            Button(action: { viewModel.removeTag(tag) }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color.diaryTertiary)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(theme.accent.opacity(0.2))
                        .clipShape(Capsule())
                    }

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
                                    .foregroundStyle(theme.accent)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.diaryCard)
                    .clipShape(Capsule())
                }
            }

            // Підказки з попередніх записів
            let suggestions = viewModel.tagSuggestions
            if !suggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(suggestions, id: \.self) { tag in
                            Button(action: {
                                viewModel.tagInput = tag
                                viewModel.addTag()
                            }) {
                                Text("#\(tag)")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.diarySecondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.diaryCard)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.diaryDivider, lineWidth: 1)
                                    )
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.tagSuggestions.count)
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
                MarkdownTextEditor(
                    text: $viewModel.text,
                    controller: editorController,
                    onFocusChange: { isTextFocused = $0 },
                    onTextChange: { viewModel.updateWordCount() }
                )
                .frame(minHeight: 200)
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
                Button(action: {
                    editorController.applyFormat(prefix: format.prefix, suffix: format.suffix)
                }) {
                    Image(systemName: format.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.diarySecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
            }
            Button(action: { editorController.resignFocus() }) {
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
        .environmentObject(AppTheme())
}
