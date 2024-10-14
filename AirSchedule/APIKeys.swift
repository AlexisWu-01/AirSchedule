//
//  APIKeys.swift
//  AirSchedule
//
//  Created by Xinyi WU on 10/14/24.
//

import Foundation

struct APIKeys {
    static func value(for key: String) -> String {
        guard let path = Bundle.main.path(forResource: "keys", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
              let value = dict[key] as? String else {
            fatalError("Could not find key \(key) in keys.plist")
        }
        return value
    }
    
    static var serpAPIKey: String {
        return value(for: "SERP_API_KEY")
    }
    
    static var openAIAPIKey: String {
        return value(for: "OPENAI_API_KEY")
    }
}
