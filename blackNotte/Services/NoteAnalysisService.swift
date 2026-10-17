import Foundation

protocol NoteAnalysisServicing {
    func analyze(_ note: ThoughtNote, mode: AgentAnalysisMode) async throws -> AnalyzeNoteResponse
    func discuss(_ note: ThoughtNote, question: String) async throws -> DiscussNoteResponse
    func draftVoiceIdea(history: String, latestUtterance: String, forceFinal: Bool) async throws -> DraftVoiceIdeaResponse
}

final class NoteAnalysisService: NoteAnalysisServicing {
    private let openAIClient: OpenAIClient

    init(openAIClient: OpenAIClient) {
        self.openAIClient = openAIClient
    }

    convenience init() throws {
        guard let configuration = OpenAIConfiguration.current else {
            throw APIConfigurationError.missingOpenAIAPIKey
        }

        self.init(openAIClient: OpenAIClient(configuration: configuration))
    }

    func analyze(_ note: ThoughtNote, mode: AgentAnalysisMode) async throws -> AnalyzeNoteResponse {
        try await openAIClient.analyze(note: note, mode: mode)
    }

    func discuss(_ note: ThoughtNote, question: String) async throws -> DiscussNoteResponse {
        try await openAIClient.discuss(note: note, question: question)
    }

    func draftVoiceIdea(history: String, latestUtterance: String, forceFinal: Bool) async throws -> DraftVoiceIdeaResponse {
        try await openAIClient.draftVoiceIdea(history: history, latestUtterance: latestUtterance, forceFinal: forceFinal)
    }
}
