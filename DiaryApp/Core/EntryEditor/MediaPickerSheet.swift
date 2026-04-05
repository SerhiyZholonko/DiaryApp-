// MARK: - Media Picker Sheet
// Bottom sheet для вибору типу медіа. Відповідає дизайну Figma.
import SwiftUI
import PhotosUI

struct MediaPickerSheet: View {
    @Binding var isPresented: Bool
    let onImages: ([UIImage]) -> Void
    let onVideos: ([URL]) -> Void
    let onAudio: (URL) -> Void

    @EnvironmentObject private var theme: AppTheme
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var showVideoPicker = false
    @State private var showVoiceRecorder = false

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.diaryDivider)
                .frame(width: 36, height: 5)
                .padding(.top, 12)

            Text("Додати медіа")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.diaryPrimaryText)
                .padding(.top, 18)
                .padding(.bottom, 24)

            // Grid
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3),
                spacing: 16
            ) {
                // Камера: відкриваємо поверх sheet (без попереднього dismiss)
                mediaOption(title: "Фотографія", icon: "camera.fill", color: Color(hex: "#FF8C42")) {
                    showCamera = true
                }
                mediaOption(title: "Галерея", icon: "photo.fill", color: Color(hex: "#4A90D9")) {
                    showPhotoPicker = true
                }
                mediaOption(title: "Відео", icon: "video.fill", color: Color(hex: "#4CAF50")) {
                    showVideoPicker = true
                }
                mediaOption(
                    title: "Голосові\nнотатки",
                    icon: "mic.fill",
                    color: Color(hex: "#9B85FF")
                ) {
                    showVoiceRecorder = true
                }
                mediaOption(
                    title: "Файли",
                    icon: "doc.fill",
                    color: Color.diarySecondary,
                    badge: "Незабаром",
                    disabled: true,
                    action: {}
                )
            }
            .padding(.horizontal, 24)

            Spacer().frame(height: 40)
        }
        .background(Color.diaryBackground)
        .fullScreenCover(isPresented: $showCamera) {
            CameraPickerView(isPresented: $showCamera) { image in
                onImages([image])
                isPresented = false
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showPhotoPicker) {
            MediaLibraryPicker(
                isPresented: $showPhotoPicker,
                filter: .images,
                onImages: { images in
                    onImages(images)
                    isPresented = false
                },
                onVideos: { _ in }
            )
        }
        .sheet(isPresented: $showVideoPicker) {
            MediaLibraryPicker(
                isPresented: $showVideoPicker,
                filter: .videos,
                onImages: { _ in },
                onVideos: { urls in
                    onVideos(urls)
                    isPresented = false
                }
            )
        }
        .sheet(isPresented: $showVoiceRecorder) {
            VoiceRecorderSheet(
                isPresented: $showVoiceRecorder,
                onAudio: { url in
                    onAudio(url)
                    isPresented = false
                }
            )
            .presentationDetents([.medium])
            .environmentObject(theme)
        }
    }

    private func mediaOption(
        title: String,
        icon: String,
        color: Color,
        badge: String? = nil,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(color.opacity(disabled ? 0.07 : 0.15))
                        .frame(width: 76, height: 76)
                    Image(systemName: icon)
                        .font(.system(size: 30))
                        .foregroundStyle(color.opacity(disabled ? 0.4 : 1))
                        .frame(width: 76, height: 76)

                    if let badge {
                        Text(badge)
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.diarySecondary.opacity(0.7))
                            .clipShape(Capsule())
                            .offset(x: 4, y: -4)
                    }
                }
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(disabled ? Color.diaryTertiary : Color.diaryPrimaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}
