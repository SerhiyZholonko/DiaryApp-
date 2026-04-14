// MARK: - Media Fullscreen View
// Перегляд медіа на весь екран з навігацією стрілками.
import SwiftUI
import AVKit

struct MediaFullscreenView: View {
    let attachments: [MediaAttachment]
    let entryId: String
    @Binding var selectedIndex: Int

    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage?
    @State private var videoPlayer: AVPlayer?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isAudioPlaying = false
    @State private var audioProgress: Double = 0
    @State private var audioTimer: Timer?

    private var current: MediaAttachment { attachments[max(0, min(selectedIndex, attachments.count - 1))] }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Content
            if current.type == .photo {
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ProgressView().tint(.white)
                }
            } else if current.type == .video {
                if let player = videoPlayer {
                    VideoPlayer(player: player)
                } else {
                    ProgressView().tint(.white)
                }
            } else if current.type == .audio {
                audioPlayerView
            }

            // Overlay
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button {
                        stopAll()
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                    }
                    Spacer()
                    if attachments.count > 1 {
                        Text("\(selectedIndex + 1) / \(attachments.count)")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(colors: [.black.opacity(0.55), .clear],
                                   startPoint: .top, endPoint: .bottom)
                )

                Spacer()

                // Arrow navigation
                if attachments.count > 1 {
                    HStack {
                        Button(action: prev) {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(.white.opacity(selectedIndex == 0 ? 0.2 : 0.8))
                        }
                        .disabled(selectedIndex == 0)

                        Spacer()

                        Button(action: next) {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(.white.opacity(selectedIndex == attachments.count - 1 ? 0.2 : 0.8))
                        }
                        .disabled(selectedIndex == attachments.count - 1)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                    .background(
                        LinearGradient(colors: [.clear, .black.opacity(0.45)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                }
            }
        }
        .onAppear { loadMedia() }
        .onChange(of: selectedIndex) { loadMedia() }
        .onDisappear { stopAll() }
    }

    // MARK: - Audio Player UI

    private var audioPlayerView: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .fill(Color.diaryPurple.opacity(0.15))
                    .frame(width: 120, height: 120)
                Image(systemName: "waveform")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.diaryPurple)
            }

            // Progress bar
            VStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.white.opacity(0.2))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.diaryPurple)
                            .frame(width: geo.size.width * audioProgress, height: 4)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 40)

                HStack {
                    Text(formatAudioTime(currentSeconds))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.6))
                    Spacer()
                    Text(formatAudioTime(Int(audioPlayer?.duration ?? 0)))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.horizontal, 40)
            }

            // Play / Pause
            Button(action: toggleAudio) {
                ZStack {
                    Circle()
                        .fill(Color.diaryPurple)
                        .frame(width: 64, height: 64)
                    Image(systemName: isAudioPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var currentSeconds: Int {
        Int((audioPlayer?.currentTime ?? 0))
    }

    private func formatAudioTime(_ seconds: Int) -> String {
        "\(seconds / 60):\(String(format: "%02d", seconds % 60))"
    }

    // MARK: - Playback control

    private func toggleAudio() {
        guard let player = audioPlayer else { return }
        if isAudioPlaying {
            player.pause()
            audioTimer?.invalidate()
            isAudioPlaying = false
        } else {
            player.play()
            isAudioPlaying = true
            startAudioTimer()
        }
    }

    private func startAudioTimer() {
        audioTimer?.invalidate()
        audioTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                guard let player = audioPlayer else { return }
                let dur = player.duration
                if dur > 0 { audioProgress = player.currentTime / dur }
                if !player.isPlaying { isAudioPlaying = false; audioTimer?.invalidate() }
            }
        }
    }

    // MARK: - Load / cleanup

    private func loadMedia() {
        stopAll()
        image = nil

        let att = current
        let eid = entryId

        if att.type == .photo {
            Task {
                image = MediaStore.shared.loadFullImage(for: att, entryId: eid)
            }
        } else if att.type == .video {
            let url = MediaStore.shared.fileURL(for: att, entryId: eid)
            videoPlayer = AVPlayer(url: url)
            videoPlayer?.play()
        } else if att.type == .audio {
            let url = MediaStore.shared.fileURL(for: att, entryId: eid)
            audioPlayer = try? AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioProgress = 0
        }
    }

    private func stopAll() {
        videoPlayer?.pause()
        videoPlayer = nil
        audioPlayer?.stop()
        audioPlayer = nil
        audioTimer?.invalidate()
        audioTimer = nil
        isAudioPlaying = false
    }

    private func prev() {
        guard selectedIndex > 0 else { return }
        selectedIndex -= 1
    }

    private func next() {
        guard selectedIndex < attachments.count - 1 else { return }
        selectedIndex += 1
    }
}
