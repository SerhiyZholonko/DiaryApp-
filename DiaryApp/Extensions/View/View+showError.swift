// MARK: - View Show Error Extension
// Використання: .showError(viewModel: viewModel)  де viewModel: ErrorDisplayable
import SwiftUI

extension View {
    func showError<VM: ErrorDisplayable & ObservableObject>(viewModel: VM) -> some View {
        modifier(ErrorViewModifier(viewModel: viewModel))
    }
}

private struct ErrorViewModifier<VM: ErrorDisplayable & ObservableObject>: ViewModifier {
    @ObservedObject var viewModel: VM
    func body(content: Content) -> some View {
        content.alert("Помилка", isPresented: Binding(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("OK") { viewModel.error = nil }
        } message: {
            if let e = viewModel.error { Text(e.localizedDescription) }
        }
    }
}
