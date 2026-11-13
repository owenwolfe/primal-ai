import XCTest
@testable import Primal

private struct ContractFixture: Decodable {
    struct Request: Decodable { let ingredientText: String }
    let request: Request
    let response: Evaluation

    static func load() throws -> ContractFixture {
        let url = try XCTUnwrap(Bundle(for: PrimalTests.self).url(forResource: "evaluation", withExtension: "json"))
        return try JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
    }
}

private struct StubEvaluator: Evaluating {
    let result: Evaluation
    func evaluate(text: String, baseURL: URL) async throws -> Evaluation { result }
}

private struct FailingEvaluator: Evaluating {
    func evaluate(text: String, baseURL: URL) async throws -> Evaluation {
        throw ScanError.message("Please check the label.")
    }
}

private struct StubRecognizer: Recognizing {
    func recognize(data: Data) async throws -> String { "oats, almonds" }
}

private actor DelayedEvaluator: Evaluating {
    private var continuation: CheckedContinuation<Evaluation, Never>?
    private var isFinished = false
    let result: Evaluation
    init(result: Evaluation) { self.result = result }

    func evaluate(text: String, baseURL: URL) async throws -> Evaluation {
        if isFinished { return result }
        return await withCheckedContinuation { continuation = $0 }
    }

    func finish() {
        isFinished = true
        continuation?.resume(returning: result)
        continuation = nil
    }

    var hasStarted: Bool { continuation != nil }
}

final class PrimalTests: XCTestCase {
    func testBackendFixtureDecodesWithoutLosingUnknownIngredients() throws {
        let fixture = try ContractFixture.load()
        XCTAssertEqual(fixture.response.status, "partial")
        XCTAssertNil(fixture.response.rating)
        XCTAssertEqual(fixture.response.unmatchedIngredients, ["mystery ingredient"])
        XCTAssertEqual(fixture.response.findings.count, 3)
        XCTAssertEqual(fixture.response.findings[1].category, "added_sweetener")
    }

    func testRequestUsesTheContractFieldName() throws {
        let data = try JSONEncoder().encode(EvaluationRequest(ingredientText: "oats"))
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: String])
        XCTAssertEqual(object, ["ingredientText": "oats"])
    }

    func testBaseURLRejectsCredentialsPathsAndInvalidSchemes() {
        XCTAssertNotNil(APIClient.validatedURL("https://api.example.com"))
        for value in ["", "api.example.com", "ftp://api.example.com", "https://a:b@example.com",
                      "https://api.example.com/other", "https://api.example.com?key=secret"] {
            XCTAssertNil(APIClient.validatedURL(value), value)
        }
    }

    @MainActor
    func testRecognitionIsEditableBeforeEvaluation() async throws {
        let fixture = try ContractFixture.load()
        let model = ScanModel(evaluator: StubEvaluator(result: fixture.response), recognizer: StubRecognizer())
        await model.recognize(Data())?.value
        XCTAssertEqual(model.text, "oats, almonds")
        XCTAssertNil(model.result)
        XCTAssertFalse(model.isBusy)
        model.text = fixture.request.ingredientText
        await model.evaluate(server: "https://api.example.com")?.value
        XCTAssertNotNil(model.result)
        XCTAssertFalse(model.isBusy)
        model.editIngredients()
        XCTAssertNil(model.result)
        XCTAssertEqual(model.text, fixture.request.ingredientText)
    }

    @MainActor
    func testErrorsPreserveTheLabelForRetry() async {
        let model = ScanModel(evaluator: FailingEvaluator(), recognizer: StubRecognizer())
        model.text = "oats"
        await model.evaluate(server: "https://api.example.com")?.value
        XCTAssertEqual(model.errorMessage, "Please check the label.")
        XCTAssertEqual(model.text, "oats")
        XCTAssertFalse(model.isBusy)
    }

    @MainActor
    func testEmptyOrOversizedLabelsDoNotStartRequests() {
        let model = ScanModel(evaluator: FailingEvaluator())
        XCTAssertNil(model.evaluate(server: "https://api.example.com"))
        model.text = String(repeating: "x", count: 8001)
        XCTAssertNil(model.evaluate(server: "https://api.example.com"))
        XCTAssertFalse(model.isBusy)
    }

    @MainActor
    func testResetDiscardsAnInFlightResult() async throws {
        let evaluator = DelayedEvaluator(result: try ContractFixture.load().response)
        let model = ScanModel(evaluator: evaluator)
        model.text = "oats"
        let task = model.evaluate(server: "https://api.example.com")
        // Give the actor bounded scheduling opportunities to receive the request.
        for _ in 0..<1000 {
            if await evaluator.hasStarted { break }
            await Task.yield()
        }
        let started = await evaluator.hasStarted
        XCTAssertTrue(started)
        model.reset()
        await evaluator.finish()
        await task?.value
        XCTAssertNil(model.result)
        XCTAssertEqual(model.text, "")
        XCTAssertFalse(model.isBusy)
    }
}
