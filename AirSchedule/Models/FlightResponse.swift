//
//  FlightResponse.swift
//  AirSchedule
//
//  Created by Xinyi WU on 10/13/24.
//

import Foundation

struct SERPFlightResponse: Codable {
    let search_metadata: SearchMetadata?
    let search_parameters: SearchParameters?
    let best_flights: [FlightGroup]?
    let other_flights: [FlightGroup]?
}

struct SearchMetadata: Codable {
    let id: String?
    let status: String?
    let json_endpoint: String?
    let created_at: String?
    let processed_at: String?
    let google_flights_url: String?
    let raw_html_file: String?
    let total_time_taken: Double?
}

struct SearchParameters: Codable {
    let engine: String?
    let departure_id: String?
    let arrival_id: String?
    let outbound_date: String?
}

struct FlightGroup: Codable {
    let flights: [FlightData]
    let total_duration: Int
    let carbon_emissions: CarbonEmissions?
    let price: Int
    let type: String
    let airline_logo: String?
    let extensions: [String]?
}

struct FlightData: Codable {
    let departure_airport: AirportInfo
    let arrival_airport: AirportInfo
    let duration: Int
    let airplane: String?
    let airline: String
    let airline_logo: String?
    let travel_class: String?
    let flight_number: String
    let legroom: String?
    let extensions: [String]?
    let often_delayed_by_over_30_min: Bool?
}

struct AirportInfo: Codable {
    let name: String
    let id: String
    let time: String
    let actual_time: String?
}
