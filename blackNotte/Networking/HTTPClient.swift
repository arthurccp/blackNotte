import Foundation

protocol HTTPClient {
    func send<RequestBody: Encodable, ResponseBody: Decodable>(
        _ endpoint: Endpoint,
        body: RequestBody,
        responseType: ResponseBody.Type
    ) async throws -> ResponseBody
}

struct Endpoint {
    let path: String
    let method: String

    static let analyzeNote = Endpoint(path: "/v1/notes/analyze", method: "POST")
}

enum NetworkError: LocalizedError {
    case invalidResponse
    case server(statusCode: Int, message: String?)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Resposta invalida do servidor."
        case let .server(statusCode, message):
            return message ?? "Erro do servidor: \(statusCode)."
        }
    }
}

final class URLSessionHTTPClient: HTTPClient {
    private let configuration: APIConfiguration
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(configuration: APIConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func send<RequestBody: Encodable, ResponseBody: Decodable>(
        _ endpoint: Endpoint,
        body: RequestBody,
        responseType: ResponseBody.Type
    ) async throws -> ResponseBody {
        let url = configuration.baseURL.appending(path: endpoint.path)
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            let error = try? decoder.decode(APIErrorResponse.self, from: data)
            throw NetworkError.server(statusCode: httpResponse.statusCode, message: error?.message)
        }

        return try decoder.decode(ResponseBody.self, from: data)
    }
}
