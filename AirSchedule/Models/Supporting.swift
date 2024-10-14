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


struct Meeting: Codable{
    let title: String
    let startTime: Date
    let location: String
}

struct Weather: Codable {
    let condition: String
    let temperature: Int
}
