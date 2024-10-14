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
}

struct Action: Codable {
    let action: String
    let parameters: [String: String]?
}
