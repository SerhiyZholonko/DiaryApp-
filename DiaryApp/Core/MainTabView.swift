// MARK: - Main Tab View
import SwiftUI

enum DiaryTab: Int, CaseIterable {
    case diary, stats, newEntry, search, profile
}

struct MainTabView: View {
    let onSignOut: () -> Void

    @EnvironmentObject private var theme: AppTheme
    @State private var selectedTab: DiaryTab = .diary
    @State private var showingEditor = false

    var body: some View {
        currentScreen
            .safeAreaInset(edge: .bottom, spacing: 0) {
                CustomTabBar(selected: $selectedTab, onNewEntry: { showingEditor = true })
            }
            .sheet(isPresented: $showingEditor) {
                EntryEditorView(entry: nil)
                    .environmentObject(theme)
            }
    }

    @ViewBuilder
    private var currentScreen: some View {
        switch selectedTab {
        case .diary:    DiaryListView(onNewEntry: { showingEditor = true })
        case .stats:    StatsView()
        case .newEntry: DiaryListView(onNewEntry: { showingEditor = true })
        case .search:   SearchView()
        case .profile:  SettingsView(onSignOut: onSignOut)
        }
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @Binding var selected: DiaryTab
    let onNewEntry: () -> Void

    @EnvironmentObject private var theme: AppTheme

    var body: some View {
        HStack(spacing: 0) {
            TabBarItem(icon: "book.closed.fill", tab: .diary,   selected: $selected)
            TabBarItem(icon: "chart.bar.fill",   tab: .stats,   selected: $selected)

            // Center FAB
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
        Button { selected = tab } label: {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(isSelected ? theme.accent : Color.diaryTertiary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainTabView(onSignOut: {})
        .environmentObject(AppTheme())
        .preferredColorScheme(.dark)
}
