//
//  SecondBrainMVPApp.swift
//  blackNotte
//
//  Created by Arthur Silva on 06/05/26.
//

import Foundation
import SwiftUI
import AVFoundation
import Speech

// MARK: - App Entry

// MARK: - Shared App State

@MainActor
final class VoiceCaptureState: ObservableObject {
    @Published var transcript: String = ""
    @Published var isRecording: Bool = false
    @Published var errorMessage: String?
    @Published var showPermissionAlert = false

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "pt-BR"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

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
        transcript = ""
        errorMessage = nil

        let audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Erro ao configurar áudio: \(error.localizedDescription)"
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
            errorMessage = "Erro ao iniciar gravação: \(error.localizedDescription)"
            return
        }

        recognitionTask = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result {
                    self?.transcript = result.bestTranscription.formattedString
                }

                if let error {
                    self?.errorMessage = "Erro no reconhecimento: \(error.localizedDescription)"
                    self?.stopRecording()
                }
            }
        }
    }

    func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        request?.endAudio()
        request = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isRecording = false
    }
}

// MARK: - Main TabBar

struct MainTabView: View {
    @StateObject private var voiceState = VoiceCaptureState()

    var body: some View {
        TabView {
            CaptureVoiceView()
                .environmentObject(voiceState)
                .tabItem {
                    Label("Capturar", systemImage: "mic.fill")
                }

            TranscriptView()
                .environmentObject(voiceState)
                .tabItem {
                    Label("Transcrição", systemImage: "text.alignleft")
                }
        }
        .tint(.orange)
        .task {
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                await voiceState.requestPermissions()
            }
        }
        .alert("Permissão necessária", isPresented: $voiceState.showPermissionAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Ative microfone e reconhecimento de fala nos ajustes do iPhone.")
        }
        .alert("Erro", isPresented: Binding(
            get: { voiceState.errorMessage != nil },
            set: { _ in voiceState.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(voiceState.errorMessage ?? "Erro desconhecido.")
        }
    }
}

// MARK: - First Tab: Voice Capture

struct CaptureVoiceView: View {
    @EnvironmentObject private var voiceState: VoiceCaptureState

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.black, Color(.systemGray6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 48) {
                    VStack(spacing: 12) {
                        Text("Second Brain")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)

                        Text(voiceState.isRecording ? "Captando sua voz..." : "Toque no círculo e fale sua ideia")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.72))
                            .multilineTextAlignment(.center)
                    }

                    Spacer()

                    AnimatedVoiceCircle(isRecording: voiceState.isRecording) {
                        voiceState.toggleRecording()
                    }

                    Spacer()

                    VStack(spacing: 8) {
                        Text(voiceState.isRecording ? "Gravando" : "Parado")
                            .font(.headline)
                            .foregroundStyle(voiceState.isRecording ? .orange : .white)

                        Text("A transcrição aparece na segunda aba.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.56))
                    }
                }
                .padding(24)
            }
        }
    }
}

// MARK: - Animated Circle Component

struct AnimatedVoiceCircle: View {
    let isRecording: Bool
    let action: () -> Void

    @State private var pulse = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(isRecording ? 0.22 : 0.12))
                    .frame(width: 240, height: 240)
                    .scaleEffect(isRecording && pulse ? 1.22 : 1.0)
                    .opacity(isRecording && pulse ? 0.25 : 0.85)

                Circle()
                    .fill(Color.orange.opacity(isRecording ? 0.34 : 0.18))
                    .frame(width: 190, height: 190)
                    .scaleEffect(isRecording && pulse ? 1.12 : 1.0)

                Circle()
                    .fill(Color.orange)
                    .frame(width: 140, height: 140)
                    .shadow(color: .orange.opacity(0.55), radius: 32, x: 0, y: 12)

                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.05).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.72), value: isRecording)
    }
}

// MARK: - Second Tab: Transcript

struct TranscriptView: View {
    @EnvironmentObject private var voiceState: VoiceCaptureState

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Transcrição")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Tudo que for captado pela voz aparece aqui em tempo real.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    ScrollView {
                        Text(voiceState.transcript.isEmpty ? "Nenhuma fala capturada ainda." : voiceState.transcript)
                            .font(.title3)
                            .foregroundStyle(voiceState.transcript.isEmpty ? .secondary : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(20)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                    }

                    HStack(spacing: 12) {
                        Button {
                            voiceState.transcript = ""
                        } label: {
                            Label("Limpar", systemImage: "trash")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                        }
                        .buttonStyle(.bordered)
                        .disabled(voiceState.transcript.isEmpty)

                        Button {
                            voiceState.toggleRecording()
                        } label: {
                            Label(
                                voiceState.isRecording ? "Parar" : "Gravar",
                                systemImage: voiceState.isRecording ? "stop.fill" : "mic.fill"
                            )
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(voiceState.isRecording ? Color.gray : Color.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
                .padding(24)
            }
        }
    }
}

#Preview {
    MainTabView()
}

/*
 Info.plist permissions needed:

 <key>NSMicrophoneUsageDescription</key>
 <string>Precisamos do microfone para capturar suas ideias por voz.</string>

 <key>NSSpeechRecognitionUsageDescription</key>
 <string>Precisamos reconhecer sua fala para transformar voz em texto.</string>

 MVP atual:
 - SwiftUI puro
 - TabBar com 2 abas
 - Aba 1: círculo central animado para captar voz
 - Aba 2: transcrição em tempo real
 - Speech-to-text em português do Brasil

 Próximos passos:
 - Salvar transcrições localmente
 - Enviar texto para IA gerar resumo, tarefa e lembrete
 - Integrar com Calendar/Reminders
 */
