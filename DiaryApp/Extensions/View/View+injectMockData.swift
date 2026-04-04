// MARK: - View Inject Mock Data
// Використання в Preview: #Preview { MyView().injectMockData() }
import SwiftUI
import Factory

extension View {
    @MainActor
    func injectMockData() -> some View {
        Container.shared.diaryStore.register { MainActor.assumeIsolated { MockDiaryStore() } }
        return self
    }
}
