// MARK: - Voice Recorder Sheet
import SwiftUI
import AVFoundation
import Combine

struct VoiceRecorderSheet: View {
    @Binding var isPresented: Bool
    let onAudio: (URL) -> Void
    let onTranscription: (String) -> Void

    @EnvironmentObject private var theme: AppTheme
    @EnvironmentObject private var lang: LanguageManager
    @StateObject private var recorder = VoiceRecorder()

    private enum SheetState { case idle, recording, done(URL), transcribing }
    @State private var state: SheetState = .idle
    @State private var transcriptionError: String?

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.diaryDivider)
                .frame(width: 36, height: 5)
                .padding(.top, 12)

            Text(lang.l("Voice Note", "Голосова нотатка"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.diaryPrimaryText)
                .padding(.top, 18)

            Spacer().frame(height: 32)

            switch state {
            case .idle, .recording:
                recordingView
            case .done(let url):
                doneView(url: url)
            case .transcribing:
                transcribingView
            }

            Spacer().frame(height: 48)
        }
        .background(Color.diaryBackground)
        .onDisappear { recorder.cancel() }
    }

    // MARK: - Recording View

    private var recordingView: some View {
        VStack(spacing: 0) {
            Text(recorder.timeString)
                .font(.system(size: 52, weight: .thin, design: .monospaced))
                .foregroundStyle(Color.diaryPrimaryText)
                .contentTransition(.numericText())

            Spacer().frame(height: 28)

            WaveformBarsView(isRecording: recorder.isRecording)
                .frame(height: 56)
                .padding(.horizontal, 32)

            Spacer().frame(height: 36)

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

            Text(recorder.isRecording ? lang.l("Tap to stop", "Натисни щоб зупинити") : lang.l("Tap to start recording", "Натисни щоб почати"))
                .font(.system(size: 13))
                .foregroundStyle(Color.diarySecondary)
        }
    }

    // MARK: - Done View

    private func doneView(url: URL) -> some View {
        VStack(spacing: 0) {
            // Duration badge
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color(hex: "#4CAF50"))
                Text("\(lang.l("Recording done", "Запис завершено")) · \(recorder.timeString)")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.diaryPrimaryText)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.diaryCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if let err = transcriptionError {
                Text(err)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "#FF4B4B"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
            }

            Spacer().frame(height: 28)

            // Transcribe button
            Button(action: { transcribe(url: url) }) {
                HStack(spacing: 8) {
                    Image(systemName: "text.bubble.fill")
                    Text(lang.l("Insert as Text", "Вставити як текст"))
                        .fontWeight(.semibold)
                }
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(theme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)

            Spacer().frame(height: 12)

            // Save audio button
            Button(action: {
                onAudio(url)
                isPresented = false
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "waveform")
                    Text(lang.l("Save Audio", "Зберегти аудіо"))
                        .fontWeight(.medium)
                }
                .font(.system(size: 16))
                .foregroundStyle(Color.diaryPrimaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color.diaryCard)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)

            Spacer().frame(height: 12)

            // Re-record link
            Button(action: {
                state = .idle
                recorder.cancel()
            }) {
                Text(lang.l("Record Again", "Записати знову"))
                    .font(.system(size: 14))
                    .foregroundStyle(Color.diarySecondary)
            }
        }
    }

    // MARK: - Transcribing View

    private var transcribingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.4)
                .tint(theme.accent)
            Text(lang.l("Recognizing speech…", "Розпізнаю текст…"))
                .font(.system(size: 15))
                .foregroundStyle(Color.diarySecondary)
        }
        .frame(minHeight: 160)
    }

    // MARK: - Actions

    private func handleRecordTap() {
        if recorder.isRecording {
            if let url = recorder.stop() {
                state = .done(url)
            }
        } else {
            state = .recording
            recorder.start()
        }
    }

    private func transcribe(url: URL) {
        transcriptionError = nil
        state = .transcribing
        Task {
            do {
                let text = try await SpeechTranscriber.shared.transcribe(url: url)
                if text.isEmpty {
                    throw SpeechTranscriber.TranscriptionError.emptyResult
                }
                onTranscription(text)
                isPresented = false
            } catch {
                state = .done(url)
                transcriptionError = error.localizedDescription
            }
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
