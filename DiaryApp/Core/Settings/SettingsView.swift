// MARK: - Settings View
// Налаштування: профіль, FaceID, нагадування, зовнішній вигляд, дані.
import SwiftUI

struct SettingsView: View {
    let onSignOut: () -> Void

    @EnvironmentObject private var theme: AppTheme
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        ZStack {
            Color.diaryBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Title
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(LinearGradient(
                                    colors: [theme.accent.opacity(0.35), theme.accent.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 36, height: 36)
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(theme.accent)
                        }
                        Text("Налаштування")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color.diaryPrimaryText)
                        Spacer()
                    }

                    profileCard

                    // Security section
                    section(title: "БЕЗПЕКА") {
                        settingsRow(icon: "lock.fill", iconColor: .yellow) {
                            Toggle("Face ID / Touch ID", isOn: Binding(
                                get: { viewModel.faceIDEnabled },
                                set: { _ in viewModel.toggleFaceID() }
                            ))
                            .tint(theme.accent)
                            .font(.system(size: 16))
                            .foregroundStyle(Color.diaryPrimaryText)
                        }

                        Divider().background(Color.diaryDivider).padding(.leading, 52)

                        settingsRow(icon: "clock.fill", iconColor: Color.diarySecondary) {
                            HStack {
                                Text("Автоблокування")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color.diaryPrimaryText)
                                Spacer()
                                Menu {
                                    ForEach(viewModel.autoLockOptions, id: \.self) { min in
                                        Button(viewModel.autoLockLabel(min)) {
                                            viewModel.autoLockMinutes = min
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(viewModel.autoLockLabel(viewModel.autoLockMinutes))
                                            .font(.system(size: 14))
                                            .foregroundStyle(theme.accentLight)
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 11))
                                            .foregroundStyle(Color.diaryTertiary)
                                    }
                                }
                            }
                        }
                    }

                    // Reminders section
                    section(title: "НАГАДУВАННЯ") {
                        settingsRow(icon: "bell.fill", iconColor: theme.accent) {
                            Toggle(isOn: Binding(
                                get: { viewModel.reminderEnabled },
                                set: { _ in viewModel.toggleReminder() }
                            )) {
                                HStack {
                                    Text("Щоденне нагадування")
                                        .font(.system(size: 16))
                                        .foregroundStyle(Color.diaryPrimaryText)
                                    Spacer()
                                    if viewModel.reminderEnabled {
                                        Text("\(viewModel.reminderHour, specifier: "%02d"):\(viewModel.reminderMinute, specifier: "%02d")")
                                            .font(.system(size: 14))
                                            .foregroundStyle(theme.accentLight)
                                    }
                                }
                            }
                            .tint(theme.accent)
                        }

                        if viewModel.reminderEnabled {
                            Divider().background(Color.diaryDivider).padding(.leading, 52)
                            settingsRow(icon: "clock.fill", iconColor: theme.accent) {
                                HStack {
                                    Text("Час нагадування")
                                        .font(.system(size: 16))
                                        .foregroundStyle(Color.diaryPrimaryText)
                                    Spacer()
                                    DatePicker(
                                        "",
                                        selection: Binding(
                                            get: { viewModel.reminderTime },
                                            set: { viewModel.reminderTime = $0 }
                                        ),
                                        displayedComponents: .hourAndMinute
                                    )
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .tint(theme.accent)
                                }
                            }
                        }

                        Divider().background(Color.diaryDivider).padding(.leading, 52)

                        settingsRow(icon: "flame.fill", iconColor: Color(hex: "#FF6B35")) {
                            HStack {
                                Text("Ціль серії")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color.diaryPrimaryText)
                                Spacer()
                                HStack(spacing: 12) {
                                    Button(action: { if viewModel.streakGoal > 1 { viewModel.streakGoal -= 1 } }) {
                                        Image(systemName: "minus.circle")
                                            .foregroundStyle(Color.diarySecondary)
                                    }
                                    Text("\(viewModel.streakGoal) днів")
                                        .font(.system(size: 14))
                                        .foregroundStyle(theme.accentLight)
                                        .frame(minWidth: 60)
                                    Button(action: { viewModel.streakGoal += 1 }) {
                                        Image(systemName: "plus.circle")
                                            .foregroundStyle(Color.diarySecondary)
                                    }
                                }
                            }
                        }
                    }

                    // Appearance section
                    section(title: "ЗОВНІШНІЙ ВИГЛЯД") {
                        settingsRow(icon: "moon.fill", iconColor: Color(hex: "#9B85FF")) {
                            HStack {
                                Text("Темна тема")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color.diaryPrimaryText)
                                Spacer()
                                Menu {
                                    Button("Системна") { viewModel.appearanceMode = 0 }
                                    Button("Темна")    { viewModel.appearanceMode = 1 }
                                    Button("Світла")   { viewModel.appearanceMode = 2 }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(["Системна", "Темна", "Світла"][viewModel.appearanceMode])
                                            .font(.system(size: 14))
                                            .foregroundStyle(theme.accentLight)
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 11))
                                            .foregroundStyle(Color.diaryTertiary)
                                    }
                                }
                            }
                        }

                        Divider().background(Color.diaryDivider).padding(.leading, 52)

                        settingsRow(icon: "paintpalette.fill", iconColor: Color(hex: "#FF8C42")) {
                            HStack {
                                Text("Акцентний колір")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color.diaryPrimaryText)
                                Spacer()
                                HStack(spacing: 8) {
                                    ForEach(AppTheme.palette.indices, id: \.self) { idx in
                                        let isSelected = theme.accentIdx == idx
                                        Circle()
                                            .fill(AppTheme.palette[idx])
                                            .frame(width: isSelected ? 28 : 24,
                                                   height: isSelected ? 28 : 24)
                                            .shadow(color: AppTheme.palette[idx].opacity(isSelected ? 0.55 : 0),
                                                    radius: 6, x: 0, y: 2)
                                            .overlay {
                                                if isSelected {
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 10, weight: .bold))
                                                        .foregroundStyle(.white)
                                                }
                                            }
                                            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isSelected)
                                            .onTapGesture {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                                                    theme.accentIdx = idx
                                                }
                                            }
                                    }
                                }
                            }
                        }
                    }

                    // AI section
                    section(title: "ШІ ПОМІЧНИК") {
                        settingsRow(icon: "sparkles", iconColor: theme.accent) {
                            Toggle(isOn: Binding(
                                get: { viewModel.aiInsightsEnabled },
                                set: { viewModel.aiInsightsEnabled = $0 }
                            )) {
                                Text("AI-підказки")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color.diaryPrimaryText)
                            }
                            .tint(theme.accent)
                        }

                    }

                    Button(action: { viewModel.signOut(completion: onSignOut) }) {
                        Text("Вийти з акаунту")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color(hex: "#FF4B4B"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.diaryCard)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Spacer().frame(height: 90)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
        .showError(viewModel: viewModel)
    }

    // MARK: - Profile Card
    private var profileCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [theme.accent.opacity(0.45), theme.accent.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 52, height: 52)
                    .shadow(color: theme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                Text(initials)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(theme.accentLight)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.currentUser?.displayName ?? "Користувач")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.diaryPrimaryText)
                Text(viewModel.currentUser?.email ?? "")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.diarySecondary)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.diaryCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    private var initials: String {
        guard let name = viewModel.currentUser?.displayName, !name.isEmpty else { return "?" }
        return name.split(separator: " ").compactMap { $0.first }.prefix(2).map { String($0) }.joined()
    }

    // MARK: - Helpers
    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.diarySecondary)
                .padding(.bottom, 8)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(Color.diaryCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color.black.opacity(0.07), radius: 10, x: 0, y: 3)
        }
    }

    private func settingsRow<Content: View>(
        icon: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(iconColor)
            }
            content()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

#Preview {
    SettingsView(onSignOut: {})
        .environmentObject(AppTheme())
        .preferredColorScheme(.dark)
}
