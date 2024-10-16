//
//  Supporting.swift
//  AirSchedule
//
//  Created by Xinyi WU on 10/13/24.
//

import Foundation

struct Context {
    var data: [String: Any] = [:]
}

struct Weather: Codable {
    let condition: String
    let temperature: Int
}
