//
//  ActionPlan.swift
//  AirSchedule
//
//  Created by Xinyi WU on 10/14/24.
//

import Foundation

struct ActionPlan: Codable {
    let intent: String
    let entities: [String: AnyCodable]
    let actions: [Action]?
    let uiComponents: [UIComponent]
    
    enum CodingKeys: String, CodingKey {
        case intent, entities, actions
        case uiComponents = "ui_components"
    }
}

// Add this struct to handle different types in JSON
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else {
            value = "Unsupported type"
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let stringValue as String:
            try container.encode(stringValue)
        default:
            try container.encode("Unsupported type")
        }
    }
}

struct Action: Codable {
    let api: String
    let method: String
    var parameters: [String: AnyCodable]?
}

struct UIComponent: Codable, Identifiable {
    let id = UUID()
    let type: String
    let properties: [String: AnyCodable]
    
    enum CodingKeys: String, CodingKey {
        case type, properties
    }
}
