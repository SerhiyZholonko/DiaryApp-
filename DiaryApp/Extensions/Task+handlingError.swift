// MARK: - Task Error Handling
// Використання: Task(handlingErrorWith: viewModel) { await viewModel.load() }
import Foundation

extension Task where Failure == Error {
    @discardableResult
    init(
        priority: TaskPriority? = nil,
        handlingErrorWith errorHandler: (any ErrorDisplayable)?,
        operation: @escaping @Sendable () async throws -> Success
    ) {
        self = Task(priority: priority) {
            do {
                return try await operation()
            } catch {
                await MainActor.run { errorHandler?.error = error }
                throw error
            }
        }
    }
}
