// MARK: - Main Tab View
import SwiftUI

enum DiaryTab: Int, CaseIterable {
    case diary, stats, newEntry, search, profile
}

struct MainTabView: View {
    let onSignOut: () -> Void

    @EnvironmentObject private var theme: AppTheme
    @State private var selectedTab: DiaryTab = .diary
    @State private var showEditor = false
    @State private var editingEntry: DiaryEntry? = nil
    @Namespace private var editorNS

    var body: some View {
        ZStack {
            currentScreen
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    CustomTabBar(
                        selected: $selectedTab,
                        onNewEntry: { openEditor(entry: nil) },
                        namespace: editorNS
                    )
                }

            if showEditor {
                EntryEditorView(entry: editingEntry, onDismiss: closeEditor)
                    .environmentObject(theme)
                    .ignoresSafeArea(.container)
                    // Для нового запису — розширюється з FAB-кнопки
                    // Для редагування — розширюється з позиції картки
                    .matchedGeometryEffect(
                        id: editingEntry?.id ?? "fab",
                        in: editorNS
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.94, anchor: .bottom)
                            .combined(with: .opacity),
                        removal: .scale(scale: 0.94, anchor: .bottom)
                            .combined(with: .opacity)
                    ))
                    .zIndex(1)
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.86), value: showEditor)
    }

    private func openEditor(entry: DiaryEntry?) {
        editingEntry = entry
        withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
            showEditor = true
        }
    }

    private func closeEditor() {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.88)) {
            showEditor = false
            editingEntry = nil
        }
    }

    private var currentScreen: some View {
        ZStack {
            DiaryListView(
                onNewEntry: { openEditor(entry: nil) },
                onEdit: { openEditor(entry: $0) },
                namespace: editorNS
            )
            .opacity(selectedTab == .diary || selectedTab == .newEntry ? 1 : 0)
            .allowsHitTesting(selectedTab == .diary || selectedTab == .newEntry)

            StatsView(onEdit: { openEditor(entry: $0) })
                .opacity(selectedTab == .stats ? 1 : 0)
                .allowsHitTesting(selectedTab == .stats)

            SearchView(onEdit: { openEditor(entry: $0) })
                .opacity(selectedTab == .search ? 1 : 0)
                .allowsHitTesting(selectedTab == .search)

            SettingsView(onSignOut: onSignOut)
                .opacity(selectedTab == .profile ? 1 : 0)
                .allowsHitTesting(selectedTab == .profile)
        }
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @Binding var selected: DiaryTab
    let onNewEntry: () -> Void
    let namespace: Namespace.ID

    @EnvironmentObject private var theme: AppTheme

    var body: some View {
        HStack(spacing: 0) {
            TabBarItem(icon: "book.closed.fill", tab: .diary,   selected: $selected)
            TabBarItem(icon: "chart.bar.fill",   tab: .stats,   selected: $selected)

            // Center FAB — джерело matchedGeometryEffect для нового запису
            Button(action: onNewEntry) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [theme.accent, theme.accentLight],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                        .shadow(color: theme.accent.opacity(0.4), radius: 8, y: 4)
                        .matchedGeometryEffect(id: "fab", in: namespace)
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .offset(y: -8)

            TabBarItem(icon: "magnifyingglass", tab: .search,  selected: $selected)
            TabBarItem(icon: "person.fill",     tab: .profile, selected: $selected)
        }
        .frame(height: 56)
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
        .background(
            Color.diaryCard
                .ignoresSafeArea(edges: .bottom)
        )
        .overlay(alignment: .top) {
            GeometryReader { proxy in
                let gap: CGFloat = 72
                let side = (proxy.size.width - gap) / 2
                HStack(spacing: 0) {
                    Rectangle().frame(width: side, height: 0.5)
                    Spacer()
                    Rectangle().frame(width: side, height: 0.5)
                }
                .foregroundStyle(Color.diaryDivider)
            }
            .frame(height: 0.5)
        }
    }
}

// MARK: - Tab Bar Item

struct TabBarItem: View {
    let icon: String
    let tab: DiaryTab
    @Binding var selected: DiaryTab

    @EnvironmentObject private var theme: AppTheme

    private var isSelected: Bool { selected == tab }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) { selected = tab }
        } label: {
            Image(systemName: icon)
                .font(.system(size: isSelected ? 21 : 20))
                .foregroundStyle(isSelected ? theme.accent : Color.diaryTertiary)
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainTabView(onSignOut: {})
        .environmentObject(AppTheme())
        .preferredColorScheme(.dark)
}
