// MARK: - Tag
// Тег для запису щоденника.
import Foundation

struct Tag: Identifiable, Codable, Hashable {
    let id: String
    var name: String

    init(id: String = UUID().uuidString, name: String) {
        self.id = id
        self.name = name
    }
}
