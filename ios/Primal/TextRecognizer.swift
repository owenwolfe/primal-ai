import Foundation
import Vision

protocol Recognizing: Sendable {
    func recognize(data: Data) async throws -> String
}

actor TextRecognizer: Recognizing {
    func recognize(data: Data) async throws -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US"]
        request.usesLanguageCorrection = true
        let handler = VNImageRequestHandler(data: data, options: [:])
        try handler.perform([request])
        let text = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ScanError.message("No text found. Try a closer photo with the label flat and well lit.")
        }
        return text
    }
}
