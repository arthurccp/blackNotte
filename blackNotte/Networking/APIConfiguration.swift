import Foundation

struct APIConfiguration {
    let baseURL: URL

    static var current: APIConfiguration? {
        guard
            let rawValue = Bundle.main.object(forInfoDictionaryKey: "BLACKNOTTE_API_BASE_URL") as? String,
            let url = URL(string: rawValue),
            !rawValue.isEmpty
        else {
            return nil
        }

        return APIConfiguration(baseURL: url)
    }
}

enum APIConfigurationError: LocalizedError {
    case missingBaseURL
    case missingOpenAIAPIKey

    var errorDescription: String? {
        switch self {
        case .missingBaseURL:
            return "Configure BLACKNOTTE_API_BASE_URL para ativar a analise com IA."
        case .missingOpenAIAPIKey:
            return "Configure OPENAI_API_KEY para ativar a analise com IA."
        }
    }
}

struct OpenAIConfiguration {
    let apiKey: String
    let model: String
    let baseURL: URL

    static var current: OpenAIConfiguration? {
        let secrets = Bundle.main.url(forResource: "Secrets", withExtension: "plist")
            .flatMap { NSDictionary(contentsOf: $0) as? [String: String] } ?? [:]

        guard let apiKey = value(for: "OPENAI_API_KEY", secrets: secrets) else {
            return nil
        }

        let model = value(for: "OPENAI_MODEL", secrets: secrets) ?? "gpt-5-mini"
        let baseURLRawValue = value(for: "OPENAI_BASE_URL", secrets: secrets) ?? "https://api.openai.com"

        return OpenAIConfiguration(
            apiKey: apiKey,
            model: model,
            baseURL: URL(string: baseURLRawValue) ?? URL(string: "https://api.openai.com")!
        )
    }

    private static func value(for key: String, secrets: [String: String]) -> String? {
        let rawValue = secrets[key] ?? Bundle.main.object(forInfoDictionaryKey: key) as? String
        guard let rawValue else { return nil }

        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            !trimmed.isEmpty,
            !trimmed.hasPrefix("$("),
            !trimmed.contains("substitua_pela_sua_chave")
        else {
            return nil
        }

        return trimmed
    }
}
