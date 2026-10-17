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

    func discuss(note: ThoughtNote, question: String) async throws -> DiscussNoteResponse {
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
                        OpenAIInputContent(
                            type: "input_text",
                            text: discussionSystemPrompt
                        )
                    ]
                ),
                OpenAIInputMessage(
                    role: "user",
                    content: [
                        OpenAIInputContent(type: "input_text", text: discussionPrompt(for: note, question: question))
                    ]
                )
            ],
            text: OpenAITextConfiguration(format: Self.discussionFormat)
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

        return try decoder.decode(DiscussNoteResponse.self, from: Data(text.utf8))
    }

    func draftVoiceIdea(history: String, latestUtterance: String, forceFinal: Bool) async throws -> DraftVoiceIdeaResponse {
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
                        OpenAIInputContent(type: "input_text", text: draftingSystemPrompt)
                    ]
                ),
                OpenAIInputMessage(
                    role: "user",
                    content: [
                        OpenAIInputContent(type: "input_text", text: draftingPrompt(history: history, latestUtterance: latestUtterance, forceFinal: forceFinal))
                    ]
                )
            ],
            text: OpenAITextConfiguration(format: Self.draftingFormat)
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

        return try decoder.decode(DraftVoiceIdeaResponse.self, from: Data(text.utf8))
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
        Se a anotacao veio de voz, corrija erros provaveis de reconhecimento, reconstrua a intencao do usuario e privilegie o significado mais provavel em vez das palavras literais.

        Origem: \(note.source.rawValue)
        Texto:
        \(note.rawText)
        """
    }

    private func discussionPrompt(for note: ThoughtNote, question: String) -> String {
        """
        O usuario quer discutir o conteudo da nota abaixo com o assistente do blackNotte.

        Responda de forma curta, natural e objetiva. O campo `response` sera lido em voz alta, entao ele deve soar como fala clara, sem listas longas.
        Se fizer sentido, desafie a premissa, mostre um gap, aponte uma consequencia futura e termine com uma pergunta boa.
        Se a nota veio de voz, corrija erros provaveis de reconhecimento e responda pelo sentido, nao pelas palavras literais.
        Nao invente contexto que nao esteja na nota ou na pergunta.

        Nota:
        \(note.rawText)

        Pergunta do usuario:
        \(question)
        """
    }

    private func draftingPrompt(history: String, latestUtterance: String, forceFinal: Bool) -> String {
        """
        Contexto da conversa ate agora:
        \(history)

        Ultima fala do usuario:
        \(latestUtterance)

        Finalizacao solicitada pelo usuario ou pelo fluxo: \(forceFinal ? "sim" : "nao")
        Se a finalizacao estiver solicitada, encerre agora mesmo e gere a anotacao final com o melhor material disponivel.

        Sua tarefa e conduzir uma entrevista curta para transformar o pensamento bruto em uma anotacao final.
        Regras:
        - faca uma unica pergunta relevante por vez enquanto a ideia ainda nao estiver fechada
        - se a fala vier com erros de reconhecimento, corrija pelo sentido
        - enquanto a anotacao nao estiver pronta, nao entregue resumo parcial nem nota final
        - mantenha o foco em descobrir o que falta: causa, objetivo, conflito, risco, consequencia, contexto ou restricao
        - quando o usuario indicar que terminou, ou quando o conteudo ja estiver suficiente, finalize
        - nao repita a fala literal
        - a resposta falada deve ser curta, natural e util
        - quando estiver finalizando, diga algo como "Entendi. Esta e a anotacao." e em seguida gere um titulo e uma descricao clara da anotacao
        - a descricao deve ser o texto final da nota, nao uma transcricao
        - nao mostre a transcricao bruta
        - se estiver faltando algo importante, pergunte antes de finalizar
        """
    }

    private let discussionSystemPrompt = """
    Voce e a inteligencia pessoal do blackNotte, em modo de discussao sobre uma nota.

    Seu trabalho e conversar com o usuario sobre o conteudo da anotacao, ajudando a pensar melhor, identificar gaps, riscos, implicacoes futuras e proximos movimentos.

    Regras:
    - responda em portugues brasileiro
    - seja curto por padrao
    - a resposta principal precisa ser natural para leitura em voz alta
    - nao invente contexto ausente
    - se a nota veio de voz, corrija erros provaveis de reconhecimento e responda pelo sentido, nao pelas palavras literais
    - se faltar contexto, sinalize isso de forma direta
    - mantenha a discussao centrada na nota e na pergunta do usuario
    - retorne JSON estrito no schema solicitado
    """

    private let draftingSystemPrompt = """
    Voce e a inteligencia pessoal do blackNotte, em modo de construcao de anotacao por voz.

    Seu objetivo e entrevistar o usuario por voz ate que a ideia fique clara o suficiente para virar uma anotacao final.

    Comportamento:
    - faca perguntas curtas, relevantes e progressivas
    - descubra o que existe por tras da ideia
    - tente entender causa, conflito, objetivo, risco, consequencia e direcao
    - corrija erros provaveis de reconhecimento de voz
    - privilegie o significado mais provavel, nao a literalidade
    - enquanto a ideia nao estiver fechada, responda com uma unica pergunta curta e relevante
    - em toda resposta, preencha title com um titulo curto do assunto abordado pelo usuario, mesmo durante as perguntas
    - nao entregue nota final antes do encerramento
    - quando houver material suficiente ou o usuario quiser encerrar, finalize a anotacao
    - produza sempre uma resposta curta para ser falada em voz alta

    Na finalizacao:
    - preencha summary com uma descricao curta da ideia em uma ou duas frases
    - em description, entregue o detalhamento separado em secoes: Resumo da ideia, Objetivo e Elementos-chave; inclua proximos passos apenas quando houver contexto
    - nao invente detalhes; sinalize o que ainda esta em aberto
    - entregue um titulo curto e forte
    - entregue uma descricao clara e util da anotacao
    - prefira iniciar com uma frase curta de fechamento como "Entendi. Esta e a anotacao."
    - deixe a descricao em formato de nota final, nao como transcricao
    - inclua topicos curtos do que foi entendido

    Regras:
    - responda em portugues brasileiro
    - seja breve por padrao
    - nao invente contexto ausente
    - retorne JSON estrito no schema solicitado
    """

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
                "topics",
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
                "topics": .stringArray("Topicos curtos do que o usuario quis dizer, corrigidos e deduzidos a partir da fala."),
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

    private static let discussionFormat = OpenAITextFormat(
        type: "json_schema",
        name: "blacknotte_note_discussion",
        schema: OpenAIJSONSchema(
            type: "object",
            additionalProperties: false,
            required: [
                "response",
                "keyPoints",
                "nextQuestion",
                "confidence"
            ],
            properties: [
                "response": .string("Resposta curta para ser lida em voz alta."),
                "keyPoints": .stringArray("Pontos centrais e objetivos da resposta."),
                "nextQuestion": .string("Uma pergunta boa para manter a discussao."),
                "confidence": .string("Nivel de confianca da leitura: alta, media ou baixa.")
            ]
        ),
        strict: true
    )

    private static let draftingFormat = OpenAITextFormat(
        type: "json_schema",
        name: "blacknotte_voice_idea_draft",
        schema: OpenAIJSONSchema(
            type: "object",
            additionalProperties: false,
            required: [
                "summary",
                "assistantMessage",
                "followUpQuestion",
                "isFinal",
                "title",
                "description",
                "topics",
                "confidence"
            ],
            properties: [
                "summary": .string("Resumo da ideia em uma ou duas frases, sem introducao. Vazio enquanto nao finalizar."),
                "assistantMessage": .string("Mensagem curta para ser dita em voz alta."),
                "followUpQuestion": .string("Uma unica pergunta curta caso a ideia ainda precise de mais contexto."),
                "isFinal": .bool("Use true quando a anotacao estiver pronta e false quando ainda faltar contexto."),
                "title": .string("Titulo curto e expressivo da anotacao final."),
                "description": .string("Descricao final da anotacao, em formato util e limpo."),
                "topics": .stringArray("Topicos curtos e corrigidos do que foi entendido."),
                "confidence": .string("Nivel de confianca da leitura: alta, media ou baixa.")
            ]
        ),
        strict: true
    )
}
