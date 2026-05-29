import Foundation
import SwiftData

@MainActor
final class NoteDetailViewModel: ObservableObject {
    @Published var isAnalyzing = false
    @Published var errorMessage: String?
    @Published var selectedMode: AgentAnalysisMode = .deepen

    func analyze(note: ThoughtNote, modelContext: ModelContext) async {
        isAnalyzing = true
        errorMessage = nil

        do {
            let service = try NoteAnalysisService()
            let response = try await service.analyze(note, mode: selectedMode)
            apply(response, to: note)
            try modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
        }

        isAnalyzing = false
    }

    private func apply(_ response: AnalyzeNoteResponse, to note: ThoughtNote) {
        let normalized = normalize(response)

        note.title = normalized.title
        note.category = normalized.category
        note.tags = normalized.tags
        note.updatedAt = .now

        note.analysis = ThoughtAnalysis(
            centralIdea: normalized.centralIdea,
            deepReading: normalized.deepReading,
            summary: normalized.summary,
            expandedText: normalized.expandedText,
            questions: normalized.questions,
            risks: normalized.risks,
            practicalTransformation: normalized.practicalTransformation,
            nextSteps: normalized.nextSteps,
            recommendedNextStep: normalized.recommendedNextStep,
            observedFacts: normalized.observedFacts,
            inferences: normalized.inferences,
            openQuestions: normalized.openQuestions,
            confidence: normalized.confidence
        )
    }

    private func normalize(_ response: AnalyzeNoteResponse) -> AnalyzeNoteResponse {
        AnalyzeNoteResponse(
            title: cleanText(response.title, fallback: "Nota aprofundada"),
            category: cleanText(response.category, fallback: "Geral"),
            tags: cleanItems(response.tags),
            centralIdea: cleanText(response.centralIdea, fallback: "Sem ideia central identificada."),
            deepReading: cleanText(response.deepReading, fallback: "Sem leitura profunda identificada."),
            summary: cleanText(response.summary, fallback: "Sem resumo gerado."),
            expandedText: cleanText(response.expandedText, fallback: "Sem expansao gerada."),
            questions: cleanItems(response.questions),
            risks: cleanItems(response.risks),
            practicalTransformation: cleanText(response.practicalTransformation, fallback: "Sem transformacao pratica definida."),
            nextSteps: cleanItems(response.nextSteps),
            recommendedNextStep: cleanText(response.recommendedNextStep, fallback: "Revisar a anotacao."),
            observedFacts: cleanItems(response.observedFacts),
            inferences: cleanItems(response.inferences),
            openQuestions: cleanItems(response.openQuestions),
            confidence: cleanText(response.confidence, fallback: "media")
        )
    }

    private func cleanText(_ text: String, fallback: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }

    private func cleanItems(_ items: [String]) -> [String] {
        var seen = Set<String>()
        return items
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { seen.insert($0.lowercased()).inserted }
    }
}
