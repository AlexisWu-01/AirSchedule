//
//  ActionPlan.swift
//  AirSchedule
//
//  Created by Xinyi WU on 10/14/24.
//

import Foundation

struct ActionPlan: Codable {
    let intent: String
    let entities: [String: String]?
    let actions: [Action]
    let uiComponents: [String]

    enum CodingKeys: String, CodingKey {
        case intent, entities, actions
        case uiComponents = "ui_components"
    }
}

struct Action: Codable {
    let api: String
    let parameters: [String: String]?
}
