// MARK: - Voice Recorder Sheet
import SwiftUI
import AVFoundation
import Combine

struct VoiceRecorderSheet: View {
    @Binding var isPresented: Bool
    let onAudio: (URL) -> Void

    @EnvironmentObject private var theme: AppTheme
    @StateObject private var recorder = VoiceRecorder()

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.diaryDivider)
                .frame(width: 36, height: 5)
                .padding(.top, 12)

            Text("Голосова нотатка")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.diaryPrimaryText)
                .padding(.top, 18)

            Spacer().frame(height: 32)

            // Timer
            Text(recorder.timeString)
                .font(.system(size: 52, weight: .thin, design: .monospaced))
                .foregroundStyle(Color.diaryPrimaryText)
                .contentTransition(.numericText())

            Spacer().frame(height: 28)

            // Waveform
            WaveformBarsView(isRecording: recorder.isRecording)
                .frame(height: 56)
                .padding(.horizontal, 32)

            Spacer().frame(height: 36)

            // Record / Stop button
            Button(action: handleRecordTap) {
                ZStack {
                    Circle()
                        .fill(recorder.isRecording
                              ? Color(hex: "#FF4B4B").opacity(0.15)
                              : theme.accent.opacity(0.15))
                        .frame(width: 88, height: 88)
                    Circle()
                        .fill(recorder.isRecording ? Color(hex: "#FF4B4B") : theme.accent)
                        .frame(width: 68, height: 68)
                    Image(systemName: recorder.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(.white)
                }
            }
            .scaleEffect(recorder.isRecording ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: recorder.isRecording)

            Spacer().frame(height: 16)

            Text(recorder.isRecording ? "Натисни щоб зупинити" : "Натисни щоб почати запис")
                .font(.system(size: 13))
                .foregroundStyle(Color.diarySecondary)

            Spacer().frame(height: 48)
        }
        .background(Color.diaryBackground)
        .onDisappear { recorder.cancel() }
    }

    private func handleRecordTap() {
        if recorder.isRecording {
            if let url = recorder.stop() {
                onAudio(url)
                isPresented = false
            }
        } else {
            recorder.start()
        }
    }
}

// MARK: - Voice Recorder

@MainActor
final class VoiceRecorder: ObservableObject {
    @Published var isRecording = false
    @Published var timeString = "0:00"

    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var elapsed = 0
    private(set) var outputURL: URL?

    func start() {
        Task {
            let granted = await AVAudioApplication.requestRecordPermission()
            guard granted else { return }
            beginRecording()
        }
    }

    private func beginRecording() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
        try? session.setActive(true)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".m4a")
        outputURL = url

        let settings: [String: Any] = [
            AVFormatIDKey:            Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey:          44100,
            AVNumberOfChannelsKey:    1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        audioRecorder = try? AVAudioRecorder(url: url, settings: settings)
        audioRecorder?.record()
        isRecording = true
        elapsed = 0

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.elapsed += 1
                self.timeString = self.formatTime(self.elapsed)
            }
        }
    }

    func stop() -> URL? {
        audioRecorder?.stop()
        invalidateTimer()
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false)
        return outputURL
    }

    func cancel() {
        audioRecorder?.stop()
        audioRecorder?.deleteRecording()
        invalidateTimer()
        isRecording = false
    }

    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func formatTime(_ seconds: Int) -> String {
        "\(seconds / 60):\(String(format: "%02d", seconds % 60))"
    }
}

// MARK: - Waveform Bars Animation

struct WaveformBarsView: View {
    let isRecording: Bool
    private let count = 32

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<count, id: \.self) { i in
                WaveBar(delay: Double(i) * 0.06, isActive: isRecording)
            }
        }
    }
}

private struct WaveBar: View {
    let delay: Double
    let isActive: Bool
    @State private var h: CGFloat = 4

    var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(isActive ? Color(hex: "#9B85FF") : Color.diaryDivider)
            .frame(width: 3, height: max(4, h))
            .onChange(of: isActive) { _, active in
                if active { animate() } else {
                    withAnimation(.easeOut(duration: 0.2)) { h = 4 }
                }
            }
    }

    private func animate() {
        withAnimation(
            .easeInOut(duration: Double.random(in: 0.25...0.55))
            .repeatForever(autoreverses: true)
            .delay(delay)
        ) {
            h = CGFloat.random(in: 10...52)
        }
    }
}
