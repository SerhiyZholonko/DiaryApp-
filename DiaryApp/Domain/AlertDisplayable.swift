// MARK: - Alert Displayable Protocol
// Підключи до ViewModel + .showAlert(viewModel:) на View.
import Foundation

protocol AlertDisplayable: AnyObject {
    var alert: AppAlert? { get set }
}
