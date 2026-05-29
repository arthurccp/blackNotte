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

struct APIErrorResponse: Decodable {
    let message: String?
}
