// MARK: - View Show Alert Extension
// Використання: .showAlert(viewModel: viewModel)  де viewModel: AlertDisplayable
import SwiftUI

extension View {
    func showAlert<VM: AlertDisplayable & ObservableObject>(viewModel: VM) -> some View {
        modifier(AlertViewModifier(viewModel: viewModel))
    }
}

private struct AlertViewModifier<VM: AlertDisplayable & ObservableObject>: ViewModifier {
    @ObservedObject var viewModel: VM
    func body(content: Content) -> some View {
        content.alert(viewModel.alert?.title ?? "", isPresented: Binding(
            get: { viewModel.alert != nil },
            set: { if !$0 { viewModel.alert = nil } }
        )) {
            Button(viewModel.alert?.actionTitle ?? "OK") {
                viewModel.alert?.action()
                viewModel.alert = nil
            }
            Button(LanguageManager.shared.l("Cancel", "Скасувати"), role: .cancel) { viewModel.alert = nil }
        } message: {
            if let msg = viewModel.alert?.message { Text(msg) }
        }
    }
}
