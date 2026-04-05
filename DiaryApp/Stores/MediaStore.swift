// MARK: - MediaStore
// Зберігає медіафайли в iCloud Documents.
// Fallback: локальний Documents якщо iCloud недоступний.
import Foundation
import UIKit
import AVFoundation

final class MediaStore {
    static let shared = MediaStore()
    private init() {}

    // MARK: - Base URL

    private var baseURL: URL {
        let fm = FileManager.default
        if let iCloud = fm.url(forUbiquityContainerIdentifier: nil)?
            .appendingPathComponent("Documents")
            .appendingPathComponent("media") {
            try? fm.createDirectory(at: iCloud, withIntermediateDirectories: true)
            return iCloud
        }
        let local = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("media")
        try? fm.createDirectory(at: local, withIntermediateDirectories: true)
        return local
    }

    var isUsingiCloud: Bool {
        FileManager.default.url(forUbiquityContainerIdentifier: nil) != nil
    }

    // MARK: - Directories

    func entryDir(entryId: String) -> URL {
        let dir = baseURL.appendingPathComponent(entryId)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func fileURL(for attachment: MediaAttachment, entryId: String) -> URL {
        entryDir(entryId: entryId).appendingPathComponent(attachment.fileName)
    }

    private func thumbnailURL(for attachment: MediaAttachment, entryId: String) -> URL? {
        guard let name = attachment.thumbnailName else { return nil }
        return entryDir(entryId: entryId).appendingPathComponent(name)
    }

    // MARK: - Save

    /// Зберігає зображення з камери або галереї. Повертає nil якщо не вдалося.
    func savePhoto(_ image: UIImage, entryId: String) -> MediaAttachment? {
        let id = UUID().uuidString
        let fileName = "\(id).jpg"
        let thumbName = "thumb_\(id).jpg"

        guard let data = image.jpegData(compressionQuality: 0.85) else { return nil }
        let thumbData = (image.preparingThumbnail(of: CGSize(width: 300, height: 300)) ?? image)
            .jpegData(compressionQuality: 0.75) ?? data

        let attachment = MediaAttachment(id: id, type: .photo, fileName: fileName, thumbnailName: thumbName)
        let dir = entryDir(entryId: entryId)
        do {
            try data.write(to: dir.appendingPathComponent(fileName))
            try thumbData.write(to: dir.appendingPathComponent(thumbName))
            return attachment
        } catch {
            return nil
        }
    }

    /// Копіює аудіозапис з тимчасового URL.
    func saveAudio(from sourceURL: URL, entryId: String) -> MediaAttachment? {
        let id = UUID().uuidString
        let ext = sourceURL.pathExtension.isEmpty ? "m4a" : sourceURL.pathExtension
        let fileName = "\(id).\(ext)"
        let attachment = MediaAttachment(id: id, type: .audio, fileName: fileName, thumbnailName: nil)
        do {
            try FileManager.default.copyItem(at: sourceURL, to: entryDir(entryId: entryId).appendingPathComponent(fileName))
            return attachment
        } catch {
            return nil
        }
    }

    /// Копіює відео з тимчасового URL та генерує мініатюру.
    func saveVideo(from sourceURL: URL, entryId: String) -> MediaAttachment? {
        let id = UUID().uuidString
        let ext = sourceURL.pathExtension.isEmpty ? "mp4" : sourceURL.pathExtension
        let fileName = "\(id).\(ext)"
        let thumbName = "thumb_\(id).jpg"

        let attachment = MediaAttachment(id: id, type: .video, fileName: fileName, thumbnailName: thumbName)
        let dir = entryDir(entryId: entryId)
        do {
            try FileManager.default.copyItem(at: sourceURL, to: dir.appendingPathComponent(fileName))
            if let thumb = generateVideoThumbnail(from: sourceURL),
               let thumbData = thumb.jpegData(compressionQuality: 0.75) {
                try? thumbData.write(to: dir.appendingPathComponent(thumbName))
            }
            return attachment
        } catch {
            return nil
        }
    }

    // MARK: - Load

    func loadThumbnail(for attachment: MediaAttachment, entryId: String) -> UIImage? {
        if let url = thumbnailURL(for: attachment, entryId: entryId),
           let data = try? Data(contentsOf: url) {
            return UIImage(data: data)
        }
        if attachment.type == .photo,
           let data = try? Data(contentsOf: fileURL(for: attachment, entryId: entryId)) {
            return UIImage(data: data)?.preparingThumbnail(of: CGSize(width: 300, height: 300))
        }
        return nil
    }

    func loadFullImage(for attachment: MediaAttachment, entryId: String) -> UIImage? {
        guard attachment.type == .photo,
              let data = try? Data(contentsOf: fileURL(for: attachment, entryId: entryId))
        else { return nil }
        return UIImage(data: data)
    }

    // MARK: - Delete

    func delete(_ attachment: MediaAttachment, entryId: String) {
        try? FileManager.default.removeItem(at: fileURL(for: attachment, entryId: entryId))
        if let url = thumbnailURL(for: attachment, entryId: entryId) {
            try? FileManager.default.removeItem(at: url)
        }
    }

    func deleteAll(entryId: String) {
        let dir = baseURL.appendingPathComponent(entryId)
        try? FileManager.default.removeItem(at: dir)
    }

    // MARK: - Helpers

    private func generateVideoThumbnail(from url: URL) -> UIImage? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 400, height: 400)

        var result: UIImage?
        let semaphore = DispatchSemaphore(value: 0)
        generator.generateCGImageAsynchronously(for: .zero) { cgImage, _, _ in
            if let cgImage { result = UIImage(cgImage: cgImage) }
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }
}
