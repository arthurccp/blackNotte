import Foundation

enum AgentAnalysisMode: String, CaseIterable, Identifiable {
    case deepen
    case organize
    case plan
    case question
    case decide

    var id: String { rawValue }

    var title: String {
        switch self {
        case .deepen:
            return "Aprofundar"
        case .organize:
            return "Organizar"
        case .plan:
            return "Plano"
        case .question:
            return "Questionar"
        case .decide:
            return "Decidir"
        }
    }

    var instruction: String {
        switch self {
        case .deepen:
            return "Aprofunde a anotacao com leitura interpretativa, possibilidades relevantes e implicacoes. Seja breve e nao transforme tudo em plano longo."
        case .organize:
            return "Reorganize a anotacao para clareza. Delimite escopo, separe ideias misturadas e torne o pensamento mais compreensivel, com respostas curtas."
        case .plan:
            return "Transforme a anotacao em proximos passos praticos. Priorize poucas acoes concretas, com foco no que falta para a ideia sair do papel."
        case .question:
            return "Questione a anotacao. Levante perguntas fortes, pontos cegos, suposicoes frageis, gaps e tensoes, sem se alongar."
        case .decide:
            return "Ajude o usuario a tomar uma decisao. Organize alternativas, criterios, tradeoffs, riscos e uma recomendacao pratica, de forma objetiva."
        }
    }
}
