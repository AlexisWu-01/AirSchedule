//
//  ActionPlan.swift
//  AirSchedule
//
//  Created by Xinyi WU on 10/14/24.
//

import Foundation

struct ActionPlan: Codable {
    let intent: String
    let entities: [String: String]
    let actions: [Action]?
    var uiComponents: [UIComponent]
    var updateUIComponents: ((inout [UIComponent], [String: AnyCodable]) -> Void)?

    enum CodingKeys: String, CodingKey {
        case intent, entities, actions
        case uiComponents = "ui_components"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        intent = try container.decode(String.self, forKey: .intent)
        entities = try container.decode([String: String].self, forKey: .entities)
        actions = try container.decodeIfPresent([Action].self, forKey: .actions)
        uiComponents = try container.decode([UIComponent].self, forKey: .uiComponents)
        updateUIComponents = { components, context in 
            for (index, component) in components.enumerated() {
                if component.type == "meetingAvailability",
                   let meetingData = context["meetingAvailabilityData"]?.value as? [String: AnyCodable] {
                    components[index].properties = meetingData
                } else if component.type == "map",
                          let mapData = context["mapData"]?.value as? [String: AnyCodable] {
                    components[index].properties["mapData"] = AnyCodable(mapData)
                } else if component.type == "text",
                          let meetingData = context["meetingAvailabilityData"]?.value as? [String: AnyCodable],
                          let canMakeIt = meetingData["canMakeIt"]?.value as? Bool,
                          let travelTime = meetingData["travelTime"]?.value as? TimeInterval {
                    let formattedTravelTime = ActionPlan.formatDuration(travelTime)
                    let message = "The travel time is \(formattedTravelTime). You will \(canMakeIt ? "be able" : "not be able") to make it to the meeting."
                    components[index].properties["content"] = AnyCodable(message)
                }
            }
        }
    }

    static private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        return "\(minutes) minutes"
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
    let id: UUID
    let type: String
    var properties: [String: AnyCodable]
    
    enum CodingKeys: String, CodingKey {
        case type, properties
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.type = try container.decode(String.self, forKey: .type)
        self.properties = try container.decode([String: AnyCodable].self, forKey: .properties)
    }

    init(type: String, properties: [String: AnyCodable]) {
        self.id = UUID()
        self.type = type
        self.properties = properties
    }
}
