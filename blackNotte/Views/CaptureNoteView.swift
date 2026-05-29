import SwiftData
import SwiftUI

struct CaptureNoteView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var voiceService: VoiceCaptureService
    @State private var noteText = ""
    @State private var lastSavedNote: ThoughtNote?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    editor
                    voiceCapture
                    saveButton

                    if let lastSavedNote {
                        NavigationLink {
                            NoteDetailView(note: lastSavedNote)
                        } label: {
                            Label("Abrir ultima nota salva", systemImage: "arrow.right.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(20)
            }
            .navigationTitle("blackNotte")
            .onChange(of: voiceService.transcript) { _, newValue in
                noteText = newValue
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Capture um pensamento")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Escreva ou fale uma ideia solta. Depois salve e aprofunde com IA.")
                .foregroundStyle(.secondary)
        }
    }

    private var editor: some View {
        TextEditor(text: $noteText)
            .frame(minHeight: 220)
            .padding(12)
            .scrollContentBackground(.hidden)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(alignment: .topLeading) {
                if noteText.isEmpty {
                    Text("Digite sua ideia, duvida, reflexao ou plano incompleto...")
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 20)
                        .allowsHitTesting(false)
                }
            }
    }

    private var voiceCapture: some View {
        Button {
            voiceService.toggleRecording()
        } label: {
            Label(
                voiceService.isRecording ? "Parar gravacao" : "Gravar por voz",
                systemImage: voiceService.isRecording ? "stop.fill" : "mic.fill"
            )
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(voiceService.isRecording ? Color.gray : Color.orange)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var saveButton: some View {
        Button {
            saveNote()
        } label: {
            Label("Salvar nota", systemImage: "tray.and.arrow.down.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
        }
        .buttonStyle(.borderedProminent)
        .disabled(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private func saveNote() {
        let text = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let source: NoteSource = voiceService.transcript == noteText && !voiceService.transcript.isEmpty ? .voice : .text
        let note = ThoughtNote(rawText: text, source: source)
        modelContext.insert(note)
        try? modelContext.save()

        lastSavedNote = note
        noteText = ""
        voiceService.transcript = ""
    }
}
