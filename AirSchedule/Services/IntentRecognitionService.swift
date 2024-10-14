//
//  IntentRecognitionService.swift
//  AirSchedule
//
//  Created by Xinyi WU on 10/14/24.
//

import Foundation

class IntentRecognitionService {
    static let shared = IntentRecognitionService()
    private let apiKey = APIKeys.openAIAPIKey

    private init() {}

    func recognizeIntent(_ query: String, completion: @escaping (Result<Intents, Error>) -> Void) {
        // Implement similar to LLMService but tailored for intent recognition
        // You can reuse the LLMService with a different prompt
    }
}

// Define your Intents struct
struct Intents: Codable {
    let intent: String
    let entities: [String: String]?
}