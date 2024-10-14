//
//  LLMResponse.swift
//  AirSchedule
//
//  Created by Xinyi WU on 10/14/24.
//

import Foundation

struct LLMResponse: Codable {
    let intent: String
    let entities: [String: String]?
    let uiSuggestion: String?
}

// Struct representing the OpenAI API's response format
struct OpenAIAPIResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let text: String
        // Include other fields if needed
    }
}
