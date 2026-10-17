import Foundation

struct AnalyzeNoteRequest: Encodable {
    let noteId: UUID
    let rawText: String
    let source: String
    let createdAt: Date
}

struct AnalyzeNoteResponse: Decodable {
    let title: String
    let category: String
    let tags: [String]
    let topics: [String]
    let centralIdea: String
    let deepReading: String
    let summary: String
    let expandedText: String
    let questions: [String]
    let risks: [String]
    let practicalTransformation: String
    let nextSteps: [String]
    let recommendedNextStep: String
    let observedFacts: [String]
    let inferences: [String]
    let openQuestions: [String]
    let confidence: String
}

struct DraftVoiceIdeaResponse: Decodable {
    var summary: String? = nil
    let assistantMessage: String
    let followUpQuestion: String
    let isFinal: Bool
    let title: String
    let description: String
    let topics: [String]
    let confidence: String
}

struct DiscussNoteResponse: Decodable {
    let response: String
    let keyPoints: [String]
    let nextQuestion: String
    let confidence: String
}

struct APIErrorResponse: Decodable {
    let message: String?
}
