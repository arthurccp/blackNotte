import Foundation
import SwiftData

enum NoteSource: String, Codable, CaseIterable {
    case text
    case voice
}

@Model
final class ThoughtNote {
    @Attribute(.unique) var id: UUID
    var rawText: String
    var sourceRawValue: String
    var createdAt: Date
    var updatedAt: Date
    var title: String
    var category: String?
    var tagsText: String
    var analysis: ThoughtAnalysis?
    var ideaSummary: String?
    var finalDetails: String?

    init(
        id: UUID = UUID(),
        rawText: String,
        source: NoteSource,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        title: String? = nil,
        category: String? = nil,
        tags: [String] = []
    ) {
        self.id = id
        self.rawText = rawText
        self.sourceRawValue = source.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.title = title ?? ThoughtNote.makeTitle(from: rawText)
        self.category = category
        self.tagsText = tags.joined(separator: "\n")
    }

    var source: NoteSource {
        get { NoteSource(rawValue: sourceRawValue) ?? .text }
        set { sourceRawValue = newValue.rawValue }
    }

    var tags: [String] {
        get { tagsText.linesList }
        set { tagsText = newValue.joined(separator: "\n") }
    }

    static func makeTitle(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Nova anotacao" }
        return String(trimmed.prefix(48))
    }
}

@Model
final class ThoughtAnalysis {
    @Attribute(.unique) var id: UUID
    var topicsText: String
    var centralIdea: String
    var deepReading: String
    var summary: String
    var expandedText: String
    var questionsText: String
    var risksText: String
    var practicalTransformation: String
    var nextStepsText: String
    var recommendedNextStep: String
    var observedFactsText: String
    var inferencesText: String
    var openQuestionsText: String
    var confidence: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        topics: [String],
        centralIdea: String,
        deepReading: String,
        summary: String,
        expandedText: String,
        questions: [String],
        risks: [String],
        practicalTransformation: String,
        nextSteps: [String],
        recommendedNextStep: String,
        observedFacts: [String],
        inferences: [String],
        openQuestions: [String],
        confidence: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.topicsText = topics.joined(separator: "\n")
        self.centralIdea = centralIdea
        self.deepReading = deepReading
        self.summary = summary
        self.expandedText = expandedText
        self.questionsText = questions.joined(separator: "\n")
        self.risksText = risks.joined(separator: "\n")
        self.practicalTransformation = practicalTransformation
        self.nextStepsText = nextSteps.joined(separator: "\n")
        self.recommendedNextStep = recommendedNextStep
        self.observedFactsText = observedFacts.joined(separator: "\n")
        self.inferencesText = inferences.joined(separator: "\n")
        self.openQuestionsText = openQuestions.joined(separator: "\n")
        self.confidence = confidence
        self.createdAt = createdAt
    }

    var topics: [String] { topicsText.linesList }
    var questions: [String] { questionsText.linesList }
    var risks: [String] { risksText.linesList }
    var nextSteps: [String] { nextStepsText.linesList }
    var observedFacts: [String] { observedFactsText.linesList }
    var inferences: [String] { inferencesText.linesList }
    var openQuestions: [String] { openQuestionsText.linesList }
}

private extension String {
    var linesList: [String] {
        split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
