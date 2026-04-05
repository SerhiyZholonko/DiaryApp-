// MARK: - Media Thumbnail Strip
// Горизонтальна стрічка мініатюр у редакторі запису.
import SwiftUI

struct MediaThumbnailStrip: View {
    let entryId: String
    let attachments: [MediaAttachment]
    let onRemove: (MediaAttachment) -> Void
    let onTap: (Int) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(attachments.enumerated()), id: \.element.id) { idx, attachment in
                    MediaThumbnailCell(
                        attachment: attachment,
                        entryId: entryId,
                        showRemove: true,
                        onRemove: { onRemove(attachment) },
                        onTap: { onTap(idx) }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
        }
    }
}

struct MediaThumbnailCell: View {
    let attachment: MediaAttachment
    let entryId: String
    var showRemove: Bool = false
    var size: CGFloat = 82
    let onRemove: () -> Void
    let onTap: () -> Void

    @State private var thumbnail: UIImage?

    private var cornerRadius: CGFloat { size * 0.146 }
    private var playIconSize: CGFloat { size * 0.34 }
    private var removeOffset: CGFloat { size * 0.073 }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onTap) {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.diaryCard)
                        .frame(width: size, height: size)

                    if let img = thumbnail {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: size, height: size)
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    } else {
                        Image(systemName: attachment.type.systemIcon)
                            .font(.system(size: size * 0.32))
                            .foregroundStyle(Color.diarySecondary)
                    }

                    if attachment.type == .video {
                        ZStack {
                            Circle()
                                .fill(.black.opacity(0.4))
                                .frame(width: playIconSize, height: playIconSize)
                            Image(systemName: "play.fill")
                                .font(.system(size: playIconSize * 0.45))
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            if showRemove {
                Button(action: onRemove) {
                    ZStack {
                        Circle()
                            .fill(.black.opacity(0.65))
                            .frame(width: 22, height: 22)
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .offset(x: removeOffset, y: -removeOffset)
            }
        }
        .frame(width: size + (showRemove ? removeOffset : 0),
               height: size + (showRemove ? removeOffset : 0))
        .onAppear { loadThumbnail() }
    }

    private func loadThumbnail() {
        let att = attachment
        let eid = entryId
        Task {
            thumbnail = MediaStore.shared.loadThumbnail(for: att, entryId: eid)
        }
    }
}
