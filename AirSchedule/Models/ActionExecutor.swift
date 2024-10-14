//
//  ActionExecutor.swift
//  AirSchedule
//
//  Created by Xinyi WU on 10/14/24.
//

import Foundation

class ActionExecutor {
    static let shared = ActionExecutor()
    
    private init() {}

    func executeAction(_ action: Action, context: inout [String: Any], completion: @escaping (Result<[String: AnyCodable], Error>) -> Void) {
        switch action.api {
        case "flight_data":
            handleFlightDataAction(action, context: &context, completion: completion)
//        case "weather":
//            handleWeatherAction(action, context: &context, completion: completion)
//        case "calendar":
//            handleCalendarAction(action, context: &context, completion: completion)
//        case "maps":
//            handleMapsAction(action, context: &context, completion: completion)
        default:
            completion(.failure(NSError(domain: "Unknown API", code: -1, userInfo: nil)))
        }
    }

    private func handleFlightDataAction(_ action: Action, context: inout [String: Any], completion: @escaping (Result<[String: AnyCodable], Error>) -> Void) {
        if let flight = context["flight"] as? Flight {
            let flightData: [String: AnyCodable] = [
                "flightNumber": AnyCodable(flight.flightNumber),
                "airline": AnyCodable(flight.airline),
                "departureAirport": AnyCodable(flight.departureAirport),
                "arrivalAirport": AnyCodable(flight.arrivalAirport),
                "departureTime": AnyCodable(flight.departureTime),
                "arrivalTime": AnyCodable(flight.arrivalTime),
                "travelClass": AnyCodable(flight.travelClass),
                "legroom": AnyCodable(flight.legroom),
                "carbonEmissions": AnyCodable(flight.carbonEmissions)
            ]
            completion(.success(flightData))
        } else {
            completion(.failure(NSError(domain: "Invalid flight data", code: -1, userInfo: nil)))
        }
    }

    // Implement other handle*Action methods as needed
}
