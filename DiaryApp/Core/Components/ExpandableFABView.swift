// MARK: - Expandable FAB View
// Floating Action Button з розкривним меню дій.
import SwiftUI

struct FABAction: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let handler: () -> Void
}

struct ExpandableFABView: View {
    var actions: [FABAction]
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            if isExpanded {
                ForEach(actions) { action in
                    Button {
                        action.handler()
                        withAnimation(.spring()) { isExpanded = false }
                    } label: {
                        HStack(spacing: 8) {
                            Text(action.title).font(.callout).foregroundStyle(Color.diaryPrimaryText)
                            Image(systemName: action.icon)
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(action.color, in: Circle())
                        }
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }

            Button {
                withAnimation(.spring()) { isExpanded.toggle() }
            } label: {
                Image(systemName: isExpanded ? "xmark" : "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.accentColor, in: Circle())
                    .rotationEffect(.degrees(isExpanded ? 45 : 0))
                    .animation(.spring(), value: isExpanded)
            }
        }
        .padding()
    }
}
