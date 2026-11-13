import Foundation

protocol Evaluating: Sendable {
    func evaluate(text: String, baseURL: URL) async throws -> Evaluation
}

struct APIClient: Evaluating {
    func evaluate(text: String, baseURL: URL) async throws -> Evaluation {
        var request = URLRequest(url: baseURL.appendingPathComponent("api/v1/evaluations"))
        request.httpMethod = "POST"
        request.timeoutInterval = 25
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(EvaluationRequest(ingredientText: text))
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        configuration.httpCookieStorage = nil
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw ScanError.message("The server returned an unexpected response.")
        }
        guard (200..<300).contains(response.statusCode) else {
            let detail = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
            throw ScanError.message(detail?.error.message ?? "The server is unavailable. Please try again.")
        }
        guard data.count <= 1_000_000 else {
            throw ScanError.message("The server response was too large.")
        }
        do {
            let result = try JSONDecoder().decode(Evaluation.self, from: data)
            guard result.schemaVersion == "1" else {
                throw ScanError.message("Please update Primal to read this result.")
            }
            return result
        } catch let error as ScanError {
            throw error
        } catch {
            throw ScanError.message("The result could not be read. Please try again.")
        }
    }

    static func validatedURL(_ value: String) -> URL? {
        guard let url = URL(string: value.trimmingCharacters(in: .whitespacesAndNewlines)),
              let host = url.host, !host.isEmpty, url.user == nil, url.password == nil,
              url.query == nil, url.fragment == nil,
              url.path.isEmpty || url.path == "/" else { return nil }
        #if DEBUG
        guard url.scheme == "https" || url.scheme == "http" else { return nil }
        #else
        guard url.scheme == "https" else { return nil }
        #endif
        return url
    }
}
