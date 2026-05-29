import SwiftData
import SwiftUI

struct NoteDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var note: ThoughtNote
    @StateObject private var viewModel = NoteDetailViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                noteContent
                agentSection
            }
            .padding(20)
        }
        .navigationTitle(note.title)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Nao foi possivel analisar", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Erro desconhecido.")
        }
    }

    private var noteContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nota original")
                .font(.headline)

            TextEditor(text: $note.rawText)
                .frame(minHeight: 160)
                .padding(12)
                .scrollContentBackground(.hidden)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onChange(of: note.rawText) { _, newValue in
                    note.title = ThoughtNote.makeTitle(from: newValue)
                    note.updatedAt = .now
                    try? modelContext.save()
                }

            if !note.tags.isEmpty {
                TagsView(tags: note.tags)
            }
        }
    }

    private var agentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Label("Agente Pensador", systemImage: "sparkles")
                    .font(.headline)

                Text(note.analysis == nil ? "Use a IA para elaborar esta anotacao." : "Analise gerada pela IA para esta anotacao.")
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

            if let analysis = note.analysis {
                Divider()
                AnalysisView(analysis: analysis)
            } else {
                Text("Nenhum aprofundamento gerado ainda.")
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
