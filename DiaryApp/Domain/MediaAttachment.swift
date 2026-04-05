// MARK: - MediaAttachment
import Foundation

struct MediaAttachment: Identifiable, Codable, Hashable {
    let id: String
    var type: MediaType
    var fileName: String
    var thumbnailName: String?

    init(id: String = UUID().uuidString, type: MediaType, fileName: String, thumbnailName: String? = nil) {
        self.id = id
        self.type = type
        self.fileName = fileName
        self.thumbnailName = thumbnailName
    }

    enum MediaType: String, Codable {
        case photo, video, audio

        var systemIcon: String {
            switch self {
            case .photo: return "photo"
            case .video: return "play.circle.fill"
            case .audio: return "waveform"
            }
        }
    }
}
