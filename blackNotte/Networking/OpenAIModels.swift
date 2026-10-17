import Foundation

struct OpenAIResponsesRequest: Encodable {
    let model: String
    let input: [OpenAIInputMessage]
    let text: OpenAITextConfiguration?
}

struct OpenAIInputMessage: Encodable {
    let role: String
    let content: [OpenAIInputContent]
}

struct OpenAIInputContent: Encodable {
    let type: String
    let text: String
}

struct OpenAITextConfiguration: Encodable {
    let format: OpenAITextFormat
}

struct OpenAITextFormat: Encodable {
    let type: String
    let name: String
    let schema: OpenAIJSONSchema
    let strict: Bool
}

struct OpenAIJSONSchema: Encodable {
    let type: String
    let additionalProperties: Bool
    let required: [String]
    let properties: [String: OpenAISchemaProperty]
}

struct OpenAISchemaProperty: Encodable {
    let type: String
    let description: String?
    let items: OpenAISchemaArrayItem?

    static func string(_ description: String) -> OpenAISchemaProperty {
        OpenAISchemaProperty(type: "string", description: description, items: nil)
    }

    static func stringArray(_ description: String) -> OpenAISchemaProperty {
        OpenAISchemaProperty(
            type: "array",
            description: description,
            items: OpenAISchemaArrayItem(type: "string")
        )
    }

    static func bool(_ description: String) -> OpenAISchemaProperty {
        OpenAISchemaProperty(type: "boolean", description: description, items: nil)
    }
}

struct OpenAISchemaArrayItem: Encodable {
    let type: String
}

struct OpenAIResponsesResponse: Decodable {
    let output: [OpenAIOutputItem]
}

struct OpenAIOutputItem: Decodable {
    let content: [OpenAIOutputContent]?
}

struct OpenAIOutputContent: Decodable {
    let type: String
    let text: String?
}

struct OpenAIErrorResponse: Decodable {
    let error: OpenAIError
}

struct OpenAIError: Decodable {
    let message: String
}
