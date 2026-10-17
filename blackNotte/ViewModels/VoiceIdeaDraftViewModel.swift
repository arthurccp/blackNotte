import AVFoundation
import Foundation
import SwiftData

@MainActor
final class VoiceIdeaDraftViewModel: NSObject, ObservableObject, @preconcurrency AVSpeechSynthesizerDelegate {
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var currentPrompt: String = "Conte o que você está pensando. Pode ser uma ideia, uma dúvida ou algo que você quer lembrar."
    @Published var topics: [String] = []
    @Published var finalTitle: String?
    @Published var finalDescription: String?
    @Published var finalNote: ThoughtNote?
    @Published var suggestedTitle = ""
    @Published var suggestedContent = ""
    private var finalSummary: String?
    @Published var savedNote: ThoughtNote?
    @Published var isCurrentOrientationSaved = false
    @Published var isFinalized = false
    @Published var isSpeaking = false

    private let speechSynthesizer = AVSpeechSynthesizer()
    private var conversationHistory: [String] = []

    override init() {
        super.init()
        speechSynthesizer.delegate = self
    }

    func reset() {
        errorMessage = nil
        currentPrompt = "Conte o que você está pensando. Pode ser uma ideia, uma dúvida ou algo que você quer lembrar."
        suggestedTitle = ""
        suggestedContent = ""
        finalSummary = nil
        savedNote = nil
        isCurrentOrientationSaved = false
        topics = []
        finalTitle = nil
        finalDescription = nil
        finalNote = nil
        isFinalized = false
        isSpeaking = false
        conversationHistory = []
    }

    func handleTurn(transcript: String) async {
        let cleaned = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            errorMessage = "Nao consegui entender o que foi dito."
            return
        }

        isProcessing = true
        errorMessage = nil

        let forceFinal = shouldFinalize(cleaned)
        conversationHistory.append("Usuario: \(cleaned)")

        do {
            let service = try NoteAnalysisService()
            let response = try await service.draftVoiceIdea(
                history: conversationHistory.joined(separator: "\n"),
                latestUtterance: cleaned,
                forceFinal: forceFinal
            )
            let normalized = normalize(response)
            topics = normalized.topics
            suggestedTitle = cleanText(normalized.title, fallback: topics.first ?? ThoughtNote.makeTitle(from: cleaned))
            isCurrentOrientationSaved = false

            if normalized.isFinal {
                finalize(with: normalized)
                finalSummary = cleanText(normalized.summary ?? "", fallback: normalized.description)
                speak(normalized.assistantMessage)
                currentPrompt = normalized.assistantMessage
            } else {
                let prompt = normalized.followUpQuestion.isEmpty ? normalized.assistantMessage : normalized.followUpQuestion
                currentPrompt = prompt
                conversationHistory.append("Assistente: \(prompt)")
                speak(prompt)
            }
            suggestedContent = currentPrompt
        } catch {
            errorMessage = error.localizedDescription
        }

        isProcessing = false
    }

    func stopSpeaking() {
        speechSynthesizer.stopSpeaking(at: .immediate)
    }

    func saveNote(modelContext: ModelContext) -> ThoughtNote? {
        guard !suggestedTitle.isEmpty, !isProcessing, !isCurrentOrientationSaved else { return nil }
        errorMessage = nil
        if let savedNote, savedNote.modelContext == nil {
            self.savedNote = nil
        }
        let note = savedNote ?? ThoughtNote(rawText: currentPrompt, source: .voice, title: suggestedTitle)
        let isNew = savedNote == nil
        let previousTitle = note.title
        let previousText = note.rawText
        let previousSummary = note.ideaSummary
        let previousDetails = note.finalDetails
        let previousUpdatedAt = note.updatedAt
        if isNew { modelContext.insert(note) }
        if !isNew {
            let separator = note.rawText.isEmpty || note.rawText.hasSuffix("\n\n") ? "" : (note.rawText.hasSuffix("\n") ? "\n" : "\n\n")
            note.rawText += separator + currentPrompt
        }
        if isFinalized {
            note.ideaSummary = finalSummary
            note.finalDetails = finalDescription
        }
        note.updatedAt = .now

        do {
            try modelContext.save()
            savedNote = note
            isCurrentOrientationSaved = true
            return note
        } catch {
            if isNew {
                modelContext.delete(note)
            } else {
                note.title = previousTitle
                note.rawText = previousText
                note.ideaSummary = previousSummary
                note.finalDetails = previousDetails
                note.updatedAt = previousUpdatedAt
            }
            errorMessage = "Não foi possível salvar a nota: \(error.localizedDescription)"
            return nil
        }
    }

    private func finalize(with response: DraftVoiceIdeaResponse) {
        let title = cleanText(response.title, fallback: ThoughtNote.makeTitle(from: response.description))
        let description = cleanText(response.description, fallback: "Ideia sem descricao final.")

        let note = ThoughtNote(
            rawText: description,
            source: .voice,
            title: title,
            category: "Ideia",
            tags: response.topics
        )

        finalTitle = title
        finalDescription = description
        finalNote = note
        isFinalized = true
    }

    private func normalize(_ response: DraftVoiceIdeaResponse) -> DraftVoiceIdeaResponse {
        DraftVoiceIdeaResponse(
            summary: response.summary,
            assistantMessage: cleanText(response.assistantMessage, fallback: "Falta um pouco mais de contexto."),
            followUpQuestion: cleanText(response.followUpQuestion, fallback: ""),
            isFinal: response.isFinal,
            title: cleanText(response.title, fallback: ""),
            description: cleanText(response.description, fallback: ""),
            topics: cleanItems(response.topics),
            confidence: cleanText(response.confidence, fallback: "media")
        )
    }

    private func shouldFinalize(_ text: String) -> Bool {
        let lowered = text.lowercased()
        return [
            "finalizar",
            "finaliza",
            "final",
            "pode fechar",
            "fecha",
            "fecha ai",
            "fecha aí",
            "encerra",
            "encerrar",
            "termina",
            "terminar",
            "pronto",
            "acabou",
            "sem mais",
            "nao tenho mais nada",
            "não tenho mais nada",
            "isso e tudo",
            "isso é tudo",
            "so isso",
            "só isso",
            "conclui",
            "concluir"
        ].contains(where: { lowered.contains($0) })
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
