import Combine
import Foundation

@MainActor
final class ScanModel: ObservableObject {
    @Published var text = "" {
        didSet { result = nil }
    }
    @Published private(set) var result: Evaluation?
    @Published private(set) var isBusy = false
    @Published private(set) var progress = ""
    @Published var errorMessage: String?
    private let evaluator: any Evaluating
    private let recognizer: any Recognizing
    private var operation: Task<Void, Never>?
    private var generation = UUID()

    init(evaluator: any Evaluating = APIClient(), recognizer: any Recognizing = TextRecognizer()) {
        self.evaluator = evaluator
        self.recognizer = recognizer
    }

    @discardableResult
    func recognize(_ data: Data) -> Task<Void, Never>? {
        guard !isBusy else { return nil }
        start("Reading your label…")
        let token = generation
        operation = Task {
            defer { if token == generation { isBusy = false } }
            do {
                let recognized = try await recognizer.recognize(data: data)
                guard !Task.isCancelled, token == generation else { return }
                text = recognized
            } catch {
                if !Task.isCancelled, token == generation {
                    errorMessage = "Could not read this photo. Try again or type the ingredients."
                }
            }
        }
        return operation
    }

    @discardableResult
    func evaluate(server: String) -> Task<Void, Never>? {
        guard !isBusy else { return nil }
        guard let url = APIClient.validatedURL(server) else {
            errorMessage = "Set a valid API address in Connection settings. Release builds require HTTPS."
            return nil
        }
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, text.count <= 8000 else {
            errorMessage = "Enter between 1 and 8,000 characters of ingredients."
            return nil
        }
        start("Looking at the ingredients…")
        let input = text
        let token = generation
        operation = Task {
            defer { if token == generation { isBusy = false } }
            do {
                let evaluation = try await evaluator.evaluate(text: input, baseURL: url)
                guard !Task.isCancelled, token == generation, text == input else { return }
                result = evaluation
            } catch {
                guard !Task.isCancelled, token == generation else { return }
                errorMessage = (error as? ScanError)?.errorDescription
                    ?? "Could not reach the server. Check your connection and try again."
            }
        }
        return operation
    }

    func editIngredients() {
        result = nil
    }

    func reset() {
        operation?.cancel()
        generation = UUID()
        isBusy = false
        text = ""
        errorMessage = nil
    }

    private func start(_ message: String) {
        generation = UUID()
        errorMessage = nil
        result = nil
        progress = message
        isBusy = true
    }
}
