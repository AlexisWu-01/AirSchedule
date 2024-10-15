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
        case "flight_data":
            handleFlightDataAction(action, context: context, completion: completion)
        case "calendar":
            handleCalendarAction(action, context: context, completion: completion)
        case "maps", "map":
            handleMapsAction(action, context: context, completion: completion)
        case "weather":
            handleWeatherAction(action, context: context, completion: completion)
        default:
            print("Unknown API: \(action.api)")
            completion(.failure(APIError.unknownAPI))
        }
    }

    private func handleFlightDataAction(_ action: Action, context: [String: Any], completion: @escaping (Result<[String: AnyCodable], Error>) -> Void) {
        if let flight = context["flight"] as? Flight {
            let flightData: [String: AnyCodable] = [
                "flightNumber": AnyCodable(flight.flightNumber),
                "airline": AnyCodable(flight.airline),
                "departureAirport": AnyCodable(flight.departureAirport),
                "arrivalAirport": AnyCodable(flight.arrivalAirport),
                "departureTime": AnyCodable(flight.departureTime),
                "arrivalTime": AnyCodable(flight.actualArrivalTime),
                "travelClass": AnyCodable(flight.travelClass),
                "legroom": AnyCodable(flight.legroom),
                "carbonEmissions": AnyCodable(flight.carbonEmissions)
            ]
            completion(.success(flightData))
        } else {
            completion(.failure(NSError(domain: "Invalid flight data", code: -1, userInfo: nil)))
        }
    }

    private func handleCalendarAction(_ action: Action, context: [String: Any], completion: @escaping (Result<[String: AnyCodable], Error>) -> Void) {
        guard let parameters = action.parameters else {
            print("Error: Missing parameters for calendar action")
            completion(.failure(NSError(domain: "Missing parameters", code: -1, userInfo: nil)))
            return
        }
        
        let event = parameters["event"]?.value as? String
        let time = parameters["time"]?.value as? String
        
        guard let flight = context["flight"] as? Flight else {
            completion(.failure(NSError(domain: "Missing flight information", code: -1, userInfo: nil)))
            return
        }
        
        let flightArrivalTime = flight.actualArrivalTime
        
        print("Executing calendar action for event: \(event ?? "nil") at time: \(time ?? "nil")")
        
        CalendarService.shared.checkAvailability(event: event, time: time, flightArrivalTime: flightArrivalTime) { result in
            switch result {
            case .success(let availabilityInfo):
                print("Calendar availability check successful: \(availabilityInfo)")
                if let isAvailable = availabilityInfo["isAvailable"] as? Bool,
                   let eventLocation = availabilityInfo["eventLocation"] as? String {
                    var updatedContext: [String: AnyCodable] = [
                        "isAvailable": AnyCodable(isAvailable),
                        "eventLocation": AnyCodable(eventLocation)
                    ]
                    if let eventStartTime = availabilityInfo["eventStartTime"] as? Date {
                        updatedContext["eventStartTime"] = AnyCodable(eventStartTime)
                    }
                    completion(.success(updatedContext))
                } else {
                    completion(.failure(NSError(domain: "Invalid availability info", code: -1, userInfo: nil)))
                }
            case .failure(let error):
                print("Calendar availability check failed: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    private func handleWeatherAction(_ action: Action, context: [String: Any], completion: @escaping (Result<[String: AnyCodable], Error>) -> Void) {
        guard let parameters = action.parameters else {
            completion(.failure(NSError(domain: "Missing parameters", code: -1, userInfo: nil)))
            return
        }
        WeatherService.shared.getForecast(location: parameters["location"]?.value as? String, time: parameters["time"]?.value as? String) { result in
            completion(result)
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

        let arrivalAirport = flight.arrivalAirport
        let arrivalTime = flight.actualArrivalTime

        print("Debug: Calling MapsService with from: \(arrivalAirport), to: \(eventLocation), arrivalTime: \(arrivalTime)")

        MapsService.shared.getDirections(from: arrivalAirport, to: eventLocation, arrivalTime: arrivalTime) { result in
            switch result {
            case .success(let (route, travelTime)):
                print("Debug: MapsService successful. Travel time: \(travelTime)")
                let updatedContext: [String: AnyCodable] = [
                    "travelTime": AnyCodable(travelTime),
                    "route": AnyCodable(route)
                ]
                completion(.success(updatedContext))
            case .failure(let error):
                print("Debug: Maps action failed: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }


}