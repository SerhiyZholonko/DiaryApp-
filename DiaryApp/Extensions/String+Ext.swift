// MARK: - String Extensions
import Foundation

extension String {
    /// true якщо не порожній і не тільки пробіли
    var isNotEmpty: Bool { !trimmingCharacters(in: .whitespaces).isEmpty }

    /// Валідація email через NSPredicate regex
    var isValidEmail: Bool {
        NSPredicate(format: "SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}").evaluate(with: self)
    }

    var capitalizingFirstLetter: String { prefix(1).uppercased() + dropFirst() }
}
