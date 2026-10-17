import AVFoundation
import Foundation
import Speech

@MainActor
final class VoiceCaptureService: ObservableObject {
    @Published var transcript: String = ""
    @Published var isRecording = false
    @Published var errorMessage: String?
    @Published var showPermissionAlert = false

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "pt-BR"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var isStoppingManually = false

    func requestPermissions() async {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        let micGranted = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }

        showPermissionAlert = !(speechStatus == .authorized && micGranted)
    }

    func toggleRecording() {
        isRecording ? stopRecording() : startRecording()
    }

    func startRecording() {
        stopRecording()
        isStoppingManually = false
        transcript = ""
        errorMessage = nil

        let audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Erro ao configurar audio: \(error.localizedDescription)"
            return
        }

        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request else { return }
        request.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            errorMessage = "Erro ao iniciar gravacao: \(error.localizedDescription)"
            return
        }

        recognitionTask = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                if let result {
                    self?.transcript = result.bestTranscription.formattedString
                }

                if let error {
                    let nsError = error as NSError
                    let isCancellation = self?.isStoppingManually == true || nsError.localizedDescription.localizedCaseInsensitiveContains("canceled") || nsError.localizedDescription.localizedCaseInsensitiveContains("cancelled")

                    if isCancellation {
                        self?.isStoppingManually = false
                        return
                    }

                    self?.errorMessage = "Erro no reconhecimento: \(error.localizedDescription)"
                    self?.stopRecording()
                }
            }
        }
    }

    func stopRecording() {
        isStoppingManually = true

        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        request?.endAudio()
        request = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isRecording = false
        isStoppingManually = false
    }

    func stopRecordingAndReturnTranscript() -> String {
        let finalTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        stopRecording()
        return finalTranscript
    }
}
