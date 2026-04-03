// MARK: - Error Displayable Protocol
// Підключи до ViewModel + .showError(viewModel:) на View.
import Foundation

protocol ErrorDisplayable: AnyObject {
    var error: Error? { get set }
}
