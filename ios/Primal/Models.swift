import Foundation

struct EvaluationRequest: Encodable, Sendable {
    let ingredientText: String
}

struct Evaluation: Decodable, Sendable {
    let schemaVersion: String
    let rulesVersion: String
    let status: String
    let rating: String?
    let findings: [Finding]
    let unmatchedIngredients: [String]
    let notice: String
    let methodology: String

    var title: String {
        guard status == "complete" else { return "A closer look needed" }
        switch rating {
        case "aligned": return "Fits your whole-food preferences"
        case "review": return "A few things to consider"
        default: return "A closer look needed"
        }
    }
}

struct Finding: Decodable, Identifiable, Sendable {
    let id: String
    let label: String
    let name: String
    let category: String
    let explanation: String
    let basis: String

    var categoryTitle: String {
        switch category {
        case "whole_food": return "Whole food"
        case "culinary": return "Kitchen staple"
        case "added_sweetener": return "Added sweetener"
        case "additive": return "Preference review"
        default: return "Not yet recognized"
        }
    }

    var isAligned: Bool { category == "whole_food" || category == "culinary" }
}

struct APIErrorResponse: Decodable {
    struct Detail: Decodable {
        let code: String
        let message: String
    }
    let error: Detail
}

enum ScanError: LocalizedError {
    case message(String)

    var errorDescription: String? {
        switch self {
        case .message(let text): return text
        }
    }
}
