//
//  Flight.swift
//  AirSchedule
//  Retrive flight information from API
//  Created by Xinyi WU on 10/13/24.
//

import Foundation

struct Flight: Identifiable {
    let id = UUID()
    let airline: String
    let airlineCode: String
    let flightNumber: String
    let departureTime: Date
    let arrivalTime: Date
    let departureAirport: String
    let arrivalAirport: String
    let price: Double
    
    // New properties
    let departureAirportName: String
    let arrivalAirportName: String
    let duration: Int
    let airplaneModel: String
    let airlineLogo: String
    let travelClass: String
    let extensions: [String]
    let legroom: String
    let isOvernight: Bool
    let oftenDelayed: Bool
    let carbonEmissions: CarbonEmissions?
}

struct CarbonEmissions: Codable {
    let this_flight: Int
    let typical_for_this_route: Int
    let difference_percent: Int
}
