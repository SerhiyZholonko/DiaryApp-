// MARK: - DI Container Registration
// Реєстрація залежностей через Factory.
// Підміна в Preview: Container.shared.diaryStore.register { MockDiaryStore() }
import Foundation
import Factory

extension Container {
    /// Сховище записів щоденника.
    var diaryStore: Factory<DiaryStoreProtocol> {
        Factory(self) { MainActor.assumeIsolated { DiaryStore() } }
    }

    /// Автентифікація (Google Sign-In + Firebase).
    var authStore: Factory<AuthStoreProtocol> {
        Factory(self) { MainActor.assumeIsolated { AuthStore() } }
    }

    /// Трекер серій.
    var streakStore: Factory<StreakStoreProtocol> {
        Factory(self) { MainActor.assumeIsolated { StreakStore() } }
    }

    /// Викликається в DiaryAppApp.init()
    func registerAll() {}
}
