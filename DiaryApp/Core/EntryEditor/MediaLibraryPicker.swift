// MARK: - Media Library Picker (PHPickerViewController wrapper)
// Handles photo and video selection from the photo library.
import SwiftUI
import PhotosUI
import UIKit
import UniformTypeIdentifiers

struct MediaLibraryPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let filter: PHPickerFilter
    let onImages: ([UIImage]) -> Void
    let onVideos: ([URL]) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = filter
        config.selectionLimit = 10
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: MediaLibraryPicker
        init(_ parent: MediaLibraryPicker) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.isPresented = false

            for result in results {
                let provider = result.itemProvider

                if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                    // Video: copy from provider temp URL to our own temp location
                    provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, _ in
                        guard let url else { return }
                        let tmp = FileManager.default.temporaryDirectory
                            .appendingPathComponent(UUID().uuidString + "." + url.pathExtension)
                        try? FileManager.default.copyItem(at: url, to: tmp)
                        DispatchQueue.main.async { self.parent.onVideos([tmp]) }
                    }
                } else if provider.canLoadObject(ofClass: UIImage.self) {
                    provider.loadObject(ofClass: UIImage.self) { obj, _ in
                        guard let image = obj as? UIImage else { return }
                        DispatchQueue.main.async { self.parent.onImages([image]) }
                    }
                }
            }
        }
    }
}
