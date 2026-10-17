import SwiftData
import SwiftUI

struct CaptureNoteView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var voiceService: VoiceCaptureService
    @State private var lastSavedNote: ThoughtNote?
    @State private var showsSavedNote = false
    @StateObject private var draftViewModel = VoiceIdeaDraftViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    voiceCapture
                    promptCard

                    if let finalNote = draftViewModel.finalNote {
                        finalNoteCard(note: finalNote)
                    }

                    if let savedNote = draftViewModel.savedNote ?? lastSavedNote {
                        NavigationLink {
                            NoteDetailView(note: savedNote)
                        } label: {
                            Label("Abrir nota salva", systemImage: "arrow.right.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(20)
            }
            .navigationTitle("blackNotte")
            .navigationDestination(isPresented: $showsSavedNote) {
                if let note = lastSavedNote {
                    NoteDetailView(note: note)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Fale sua ideia.")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Conte do seu jeito. Algumas perguntas ajudam a organizar suas ideias e transformar pensamentos soltos em uma nota clara.")
                .foregroundStyle(.secondary)
        }
    }

    private var voiceCapture: some View {
        VStack(spacing: 12) {
            VoiceOrbButton(
                isRecording: voiceService.isRecording,
                isLoading: draftViewModel.isProcessing,
                title: voiceService.isRecording ? "Parar gravacao" : "Gravar por voz",
                subtitle: voiceService.isRecording ? "Toque para encerrar e continuar a conversa." : "Toque para começar a falar."
            ) {
                handleVoiceCapture()
            }
            .frame(maxWidth: .infinity)
            .disabled(draftViewModel.isProcessing)

            if voiceService.isRecording {
                Text("Gravando...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var promptCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(draftViewModel.suggestedTitle.isEmpty ? "Vamos começar?" : "Orientação")
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(draftViewModel.currentPrompt)
                .foregroundStyle(.secondary)

            if !draftViewModel.suggestedTitle.isEmpty {
                Text(draftViewModel.suggestedTitle)
                    .font(.headline)

                Button {
                    if let note = draftViewModel.saveNote(modelContext: modelContext) {
                        lastSavedNote = note
                        draftViewModel.stopSpeaking()
                        if draftViewModel.isFinalized {
                            draftViewModel.reset()
                            voiceService.transcript = ""
                        }
                        showsSavedNote = true
                    }
                } label: {
                    Label(draftViewModel.isCurrentOrientationSaved ? "Salvo em Notas" : "Salvar em Notas", systemImage: draftViewModel.isCurrentOrientationSaved ? "checkmark" : "square.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
                .disabled(draftViewModel.isProcessing || voiceService.isRecording || draftViewModel.isCurrentOrientationSaved)

                Text(draftViewModel.savedNote == nil ? "Salva o texto desta orientação na sua nota." : "Acrescenta a orientação ao final da mesma nota.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let errorMessage = draftViewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func finalNoteCard(note: ThoughtNote) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sua ideia ganhou forma.")
                .font(.headline)

            Text(note.title)
                .font(.title3)
                .fontWeight(.semibold)

            Text(note.rawText)
                .foregroundStyle(.secondary)

            if !draftViewModel.topics.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tópicos da ideia")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    FlowTags(tags: draftViewModel.topics)
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func handleVoiceCapture() {
        if voiceService.isRecording {
            let transcript = voiceService.stopRecordingAndReturnTranscript()

            Task {
                await draftViewModel.handleTurn(transcript: transcript)

                if draftViewModel.finalNote != nil {
                    lastSavedNote = draftViewModel.savedNote
                    voiceService.transcript = ""
                }
            }
        } else {
            if draftViewModel.isFinalized {
                draftViewModel.reset()
            }

            voiceService.startRecording()
        }
    }
}

private struct FlowTags: View {
    let tags: [String]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(Capsule())
            }
        }
    }
}
