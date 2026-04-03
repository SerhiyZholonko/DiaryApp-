// MARK: - Skeleton Cell
// Loading placeholder. Використовуй коли isLoading = true.
import SwiftUI

struct SkeletonCell: View {
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.secondary.opacity(0.25))
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 8) {
                Capsule()
                    .fill(Color.secondary.opacity(0.25))
                    .frame(maxWidth: .infinity)
                    .frame(height: 14)
                Capsule()
                    .fill(Color.secondary.opacity(0.25))
                    .frame(width: 130, height: 10)
            }
        }
        .padding(.vertical, 4)
        .redacted(reason: .placeholder)
    }
}

#Preview { List { ForEach(0..<5, id: \.self) { _ in SkeletonCell() } } }
