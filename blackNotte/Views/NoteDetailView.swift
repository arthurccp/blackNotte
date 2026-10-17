import SwiftData
import SwiftUI

struct NoteDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var note: ThoughtNote
    @StateObject private var viewModel = NoteDetailViewModel()
    @StateObject private var voiceService = VoiceCaptureService()

    @State private var saveError: String?

    var body: some View {
        ScrollView {
        VStack(alignment: .leading, spacing: 16) {
            Text(note.title)
                .font(.title2)
                .fontWeight(.semibold)
                .textSelection(.enabled)

            if note.finalDetails != nil {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sua ideia ganhou forma.")
                        .font(.headline)
                    TextEditor(text: Binding(
                        get: { note.finalDetails ?? "" },
                        set: { note.finalDetails = $0 }
                    ))
                    .frame(minHeight: 300)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .accessibilityLabel("Detalhamento da ideia")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            TextEditor(text: $note.rawText)
                .frame(minHeight: 300)
                .font(.body)
                .scrollContentBackground(.hidden)
                .overlay(alignment: .topLeading) {
                    if note.rawText.isEmpty {
                        Text("Escreva suas ideias aqui…")
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                }
                .accessibilityLabel("Conteúdo da anotação")
        }
        .padding(20)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: note.rawText) { _, _ in
            note.updatedAt = .now
            saveChanges()
        }
        .onChange(of: note.finalDetails) { _, _ in
            note.updatedAt = .now
            saveChanges()
        }
        .onDisappear {
            saveChanges()
        }
        .alert("Não foi possível salvar", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("Tentar novamente") { saveChanges() }
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveError ?? "")
        }
    }

    private func saveChanges() {
        do {
            try modelContext.save()
            saveError = nil
        } catch {
            saveError = error.localizedDescription
        }
    }

    private var agentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Label("Agente Pensador", systemImage: "sparkles")
                    .font(.headline)

                Text(note.analysis == nil ? "Use a IA para interpretar esta anotacao." : "Interpretacao gerada pela IA para esta anotacao.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            modeSelector

            Button {
                Task {
                    await viewModel.analyze(note: note, modelContext: modelContext)
                }
            } label: {
                HStack {
                    if viewModel.isAnalyzing {
                        ProgressView()
                    }

                    Text(note.analysis == nil ? "Aprofundar com IA" : "Aprofundar novamente")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isAnalyzing || note.rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            Button {
                viewModel.isDiscussionVisible.toggle()
            } label: {
                HStack {
                    Image(systemName: viewModel.isDiscussionVisible ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right")
                    Text(viewModel.isDiscussionVisible ? "Fechar discussao" : "Discutir por voz")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
            }
            .buttonStyle(.bordered)
            .disabled(note.rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            if viewModel.isDiscussionVisible {
                discussionSection
            }

            if let analysis = note.analysis {
                Divider()
                AnalysisView(analysis: analysis)
            } else {
                Text("Nenhuma interpretacao gerada ainda.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var discussionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Discutir a nota")
                .font(.headline)

            Text("Faça uma pergunta sobre esta nota e ouça a resposta.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VoiceOrbButton(
                isRecording: voiceService.isRecording,
                isLoading: viewModel.isDiscussing,
                title: voiceService.isRecording ? "Parar e enviar" : "Gravar pergunta",
                subtitle: voiceService.isRecording ? "Toque para encerrar e enviar sua pergunta." : "Toque para comecar a falar."
            ) {
                handleVoiceDiscussion()
            }
            .disabled(viewModel.isDiscussing)

            if voiceService.isRecording {
                Text("Gravando sua pergunta...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let errorMessage = viewModel.discussionErrorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if let response = viewModel.discussionResponse {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Resposta falada", systemImage: "speaker.wave.2.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text("A resposta foi falada no aparelho. Use o botao abaixo para ouvir de novo.")
                        .foregroundStyle(.secondary)

                    HStack {
                        Text("Confianca: \(response.confidence.capitalized)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button {
                            viewModel.speakDiscussionResponse()
                        } label: {
                            Label("Ouvir novamente", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(16)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func handleVoiceDiscussion() {
        if voiceService.isRecording {
            let question = voiceService.stopRecordingAndReturnTranscript()
            viewModel.resetDiscussionState()

            Task {
                await viewModel.discuss(note: note, question: question)
            }
        } else {
            Task {
                await voiceService.requestPermissions()
                guard !voiceService.showPermissionAlert else { return }
                viewModel.stopSpeaking()
                viewModel.resetDiscussionState()
                voiceService.startRecording()
            }
        }
    }

    private var modeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Modo")
                .font(.subheadline)
                .fontWeight(.semibold)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(AgentAnalysisMode.allCases) { mode in
                        Button {
                            viewModel.selectedMode = mode
                        } label: {
                            Text(mode.title)
                                .font(.subheadline)
                                .fontWeight(viewModel.selectedMode == mode ? .semibold : .regular)
                                .padding(.horizontal, 12)
                                .frame(height: 36)
                                .foregroundStyle(viewModel.selectedMode == mode ? .white : .primary)
                                .background(viewModel.selectedMode == mode ? Color.orange : Color(.secondarySystemBackground))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.isAnalyzing)
                    }
                }
            }

            Text(viewModel.selectedMode.instruction)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct AnalysisView: View {
    let analysis: ThoughtAnalysis

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ListBlock(title: "Topicos", items: analysis.topics)
            SectionBlock(title: "Confianca", text: analysis.confidence.capitalized)
            ListBlock(title: "Fatos observados", items: analysis.observedFacts)
            ListBlock(title: "Inferencias", items: analysis.inferences)
            ListBlock(title: "Perguntas em aberto", items: analysis.openQuestions)
            SectionBlock(title: "Ideia central", text: analysis.centralIdea)
            SectionBlock(title: "Leitura profunda", text: analysis.deepReading)
            SectionBlock(title: "Resumo", text: analysis.summary)
            SectionBlock(title: "Expansao da ideia", text: analysis.expandedText)
            SectionBlock(title: "Transformacao pratica", text: analysis.practicalTransformation)
            ListBlock(title: "Perguntas", items: analysis.questions)
            ListBlock(title: "Riscos e pontos cegos", items: analysis.risks)
            ListBlock(title: "Proximos passos", items: analysis.nextSteps)
            SectionBlock(title: "Proximo passo recomendado", text: analysis.recommendedNextStep)
        }
    }
}

private struct SectionBlock: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(text)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ListBlock: View {
    let title: String
    let items: [String]

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)

                ForEach(items, id: \.self) { item in
                    Label(item, systemImage: "checkmark.circle")
                        .labelStyle(.titleAndIcon)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct TagsView: View {
    let tags: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(Capsule())
                }
            }
        }
    }
}
