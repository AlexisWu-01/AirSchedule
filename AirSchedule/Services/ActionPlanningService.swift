//
//  ActionPlanningService.swift
//  AirSchedule
//
//  Created by Xinyi WU on 10/14/24.
//

import Foundation

class ActionPlanningService {
    static let shared = ActionPlanningService()
    private let apiKey = APIKeys.openAIAPIKey

    private init() {}

    func planActions(for intents: Intents, completion: @escaping (Result<ActionPlan, Error>) -> Void) {
        // Implement LLM call to generate action plan based on intents
    }
}