import Foundation

protocol NoteAnalysisServicing {
    func analyze(_ note: ThoughtNote, mode: AgentAnalysisMode) async throws -> AnalyzeNoteResponse
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
}
