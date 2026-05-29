import Foundation

final class OpenAIClient {
    private let configuration: OpenAIConfiguration
    private let session: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(configuration: OpenAIConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    func analyze(note: ThoughtNote, mode: AgentAnalysisMode) async throws -> AnalyzeNoteResponse {
        let url = configuration.baseURL.appending(path: "/v1/responses")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")

        request.httpBody = try encoder.encode(OpenAIResponsesRequest(
            model: configuration.model,
            input: [
                OpenAIInputMessage(
                    role: "system",
                    content: [
                        OpenAIInputContent(type: "input_text", text: BlackNotteAgentPrompt.system)
                    ]
                ),
                OpenAIInputMessage(
                    role: "user",
                    content: [
                        OpenAIInputContent(type: "input_text", text: userPrompt(for: note, mode: mode))
                    ]
                )
            ],
            text: OpenAITextConfiguration(format: Self.analysisFormat)
        ))

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            let error = try? decoder.decode(OpenAIErrorResponse.self, from: data)
            throw NetworkError.server(statusCode: httpResponse.statusCode, message: error?.error.message)
        }

        let openAIResponse = try decoder.decode(OpenAIResponsesResponse.self, from: data)
        guard
            let text = openAIResponse.output
                .compactMap({ $0.content })
                .flatMap({ $0 })
                .first(where: { $0.type == "output_text" })?
                .text
        else {
            throw NetworkError.invalidResponse
        }

        return try decoder.decode(AnalyzeNoteResponse.self, from: Data(text.utf8))
    }

    private func userPrompt(for note: ThoughtNote, mode: AgentAnalysisMode) -> String {
        """
        Analise a anotacao abaixo como uma entrada do blackNotte.
        Modo escolhido pelo usuario: \(mode.title)
        Instrucao especifica do modo: \(mode.instruction)

        Priorize esse modo na resposta. Preencha todos os campos do JSON, mas ajuste a profundidade ao modo escolhido. Evite resposta abrangente demais quando o modo pedir foco.
        Use a politica de rastreabilidade do sistema: separe fatos observados, inferencias, perguntas em aberto e nivel de confianca. Nao invente contexto ausente.
        Mantenha a resposta compacta: pense em comentarios breves e incisivos, com diagnostico, causa provavel, gaps e proximo passo. Nao escreva textos longos.
        Se a nota for curta, a resposta tambem deve ser curta.

        Origem: \(note.source.rawValue)
        Texto:
        \(note.rawText)
        """
    }

    private static let analysisFormat = OpenAITextFormat(
        type: "json_schema",
        name: "blacknotte_note_analysis",
        schema: OpenAIJSONSchema(
            type: "object",
            additionalProperties: false,
            required: [
                "title",
                "category",
                "tags",
                "centralIdea",
                "deepReading",
                "summary",
                "expandedText",
                "questions",
                "risks",
                "practicalTransformation",
                "nextSteps",
                "recommendedNextStep",
                "observedFacts",
                "inferences",
                "openQuestions",
                "confidence"
            ],
            properties: [
                "title": .string("Titulo curto e claro para a anotacao."),
                "category": .string("Categoria principal da anotacao."),
                "tags": .stringArray("Tags objetivas relacionadas ao conteudo."),
                "centralIdea": .string("Ideia central da anotacao em uma frase."),
                "deepReading": .string("Leitura profunda da intencao, incomodo, desejo, duvida ou oportunidade por tras da anotacao."),
                "summary": .string("Resumo claro do pensamento registrado."),
                "expandedText": .string("Versao aprofundada e organizada da anotacao."),
                "questions": .stringArray("Perguntas que ajudam o usuario a amadurecer a ideia."),
                "risks": .stringArray("Riscos, contradicoes ou pontos cegos."),
                "practicalTransformation": .string("Transformacao pratica da anotacao em plano, checklist, decisao, hipotese, roteiro ou reflexao guiada."),
                "nextSteps": .stringArray("Proximos passos praticos e acionaveis."),
                "recommendedNextStep": .string("Uma acao simples, concreta e recomendada como proximo passo principal."),
                "observedFacts": .stringArray("Fatos explicitamente presentes na anotacao."),
                "inferences": .stringArray("Inferencias plausiveis, separadas dos fatos."),
                "openQuestions": .stringArray("Perguntas que permanecem em aberto ou precisam de contexto."),
                "confidence": .string("Nivel de confianca da leitura: alta, media ou baixa.")
            ]
        ),
        strict: true
    )
}
