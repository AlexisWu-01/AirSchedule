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
    
    func executeAction(_ action: Action, context: [String: Any], completion: @escaping (Result<[String: AnyCodable], Error>) -> Void) {
        switch action.api {
        case "calendar":
            handleCalendarAction(action, context: context) { result in
                DispatchQueue.main.async {
                    completion(result)
                }
            }
        case "flight_data":
            handleFlightDataAction(action, context: context) { result in
                DispatchQueue.main.async {
                    completion(result)
                }
            }
        case "maps":
            handleMapsAction(action, context: context) { result in
                DispatchQueue.main.async {
                    completion(result)
                }
            }
        default:
            DispatchQueue.main.async {
                completion(.failure(APIError.unknown))
            }
        }
    }
    
    private func handleCalendarAction(_ action: Action, context: [String: Any], completion: @escaping (Result<[String: AnyCodable], Error>) -> Void) {
        // Implement calendar action handling
        // Ensure all context updates are wrapped in main thread
        DispatchQueue.global().async {
            // Simulate fetching event details
            // Replace this with actual calendar API integration
            guard let event = action.parameters?["event"]?.value as? String else {
                completion(.failure(APIError.invalidParameters))
                return
            }
            
            // Simulate successful fetch
            let eventDetails: [String: AnyCodable] = [
                "eventStartTime": AnyCodable(Date()),
                "isAvailable": AnyCodable(true),
                "event": AnyCodable(event),
                "eventLocation": AnyCodable("Apple Park\nApple Inc., 1 Apple Park Way, Cupertino, CA 95014, United States"),
                "flightArrivalTime": AnyCodable((context["flight"] as? Flight)?.arrivalTime ?? Date()),
                "timeDifference": AnyCodable(11040.0) // Example value
            ]
            completion(.success(eventDetails))
        }
    }
    
    private func handleFlightDataAction(_ action: Action, context: [String: Any], completion: @escaping (Result<[String: AnyCodable], Error>) -> Void) {
        // Implement flight data action handling
        DispatchQueue.global().async {
            // Simulate fetching flight status
            // Replace this with actual flight API integration
            guard let flightNumber = action.parameters?["flightNumber"]?.value as? String else {
                completion(.failure(APIError.invalidParameters))
                return
            }
            
            // Simulate successful fetch
            let flightStatus: [String: AnyCodable] = [
                "flightNumber": AnyCodable(flightNumber),
                "status": AnyCodable("On Time")
            ]
            completion(.success(flightStatus))
        }
    }
    
    private func handleMapsAction(_ action: Action, context: [String: Any], completion: @escaping (Result<[String: AnyCodable], Error>) -> Void) {
        print("Debug: Entering handleMapsAction")
        print("Debug: Action parameters: \(String(describing: action.parameters))")
        print("Debug: Context: \(context)")
        
        guard let flight = context["flight"] as? Flight else {
            print("Error: Missing flight data in context")
            completion(.failure(APIError.invalidParameters))
            return
        }
        
        guard let eventLocation = context["eventLocation"] as? String else {
            print("Error: Missing eventLocation in context")
            completion(.failure(APIError.invalidParameters))
            return
        }
        
        let from = flight.arrivalAirport // Use the flight's arrival airport
        let to = eventLocation
        let arrivalTime = flight.actualArrivalTime
        
        // Use MapsService to fetch directions
        MapsService.shared.getDirections(from: from, to: to, arrivalTime: arrivalTime) { result in
            switch result {
            case .success(let (route, travelTime, sourceCoordinate, destinationCoordinate)):
                let mapData: [String: AnyCodable] = [
                    "fromLocation": AnyCodable(sourceCoordinate),
                    "toLocation": AnyCodable(destinationCoordinate),
                    "travelTime": AnyCodable(travelTime),
                    "route": AnyCodable(route)
                ]
                completion(.success(mapData))
            case .failure(let error):
                print("Debug: Maps action failed: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
}
