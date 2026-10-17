import AVFoundation
import Foundation
import SwiftData

@MainActor
final class NoteDetailViewModel: NSObject, ObservableObject, @preconcurrency AVSpeechSynthesizerDelegate {
    @Published var isAnalyzing = false
    @Published var errorMessage: String?
    @Published var selectedMode: AgentAnalysisMode = .deepen
    @Published var isDiscussionVisible = false
    @Published var isDiscussing = false
    @Published var discussionErrorMessage: String?
    @Published var discussionResponse: DiscussNoteResponse?
    @Published var isSpeaking = false

    private let speechSynthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        speechSynthesizer.delegate = self
    }

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

    func discuss(note: ThoughtNote, question: String) async {
        let trimmedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuestion.isEmpty else {
            discussionErrorMessage = "A pergunta de voz veio vazia."
            return
        }

        isDiscussing = true
        discussionErrorMessage = nil

        do {
            let service = try NoteAnalysisService()
            let response = try await service.discuss(note, question: trimmedQuestion)
            let normalized = normalize(response)
            discussionResponse = normalized
            speak(normalized.response)
        } catch {
            discussionErrorMessage = error.localizedDescription
        }

        isDiscussing = false
    }

    func resetDiscussionState() {
        discussionErrorMessage = nil
        discussionResponse = nil
        isSpeaking = false
    }

    func stopSpeaking() {
        speechSynthesizer.stopSpeaking(at: .immediate)
    }

    func speakDiscussionResponse() {
        guard let response = discussionResponse else { return }
        speak(response.response)
    }

    private func apply(_ response: AnalyzeNoteResponse, to note: ThoughtNote) {
        let normalized = normalize(response)

        note.title = normalized.title
        note.category = normalized.category
        note.tags = normalized.tags
        note.updatedAt = .now

        note.analysis = ThoughtAnalysis(
            topics: normalized.topics,
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
            topics: cleanItems(response.topics),
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

    private func normalize(_ response: DiscussNoteResponse) -> DiscussNoteResponse {
        DiscussNoteResponse(
            response: cleanText(response.response, fallback: "Nao consegui estruturar uma resposta.")
                .replacingOccurrences(of: "\n", with: " "),
            keyPoints: cleanItems(response.keyPoints),
            nextQuestion: cleanText(response.nextQuestion, fallback: "O que nesta nota ainda nao foi dito?"),
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

    private func speak(_ text: String) {
        stopSpeaking()

        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "pt-BR")
        utterance.rate = 0.48
        speechSynthesizer.speak(utterance)
        isSpeaking = true
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
}
