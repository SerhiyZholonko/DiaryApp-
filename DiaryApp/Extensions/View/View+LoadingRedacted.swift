// MARK: - View Loading Redacted
// Використання: .loadingRedacted(isLoading: viewModel.isLoading)
import SwiftUI

extension View {
    func loadingRedacted(isLoading: Bool) -> some View {
        redacted(reason: isLoading ? .placeholder : [])
        // .shimmering(active: isLoading)  ← розкоментуй якщо є markiv/Shimmer SPM
    }
}
