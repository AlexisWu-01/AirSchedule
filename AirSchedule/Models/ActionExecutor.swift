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
        DispatchQueue.global().async {
            guard let event = action.parameters?["event"]?.value as? String,
                  let flight = context["flight"] as? Flight else {
                completion(.failure(APIError.invalidParameters))
                return
            }
            
            let flightArrivalTime = flight.actualArrivalTime ?? flight.arrivalTime
            
            CalendarService.shared.checkAvailability(event: event, time: nil, flightArrivalTime: flightArrivalTime) { result in
                switch result {
                case .success(let availabilityInfo):
                    if let eventStartTime = availabilityInfo["eventStartTime"] as? Date {
                        let meetingAvailabilityData: [String: AnyCodable] = [
                            "title": AnyCodable(availabilityInfo["event"] as? String ?? ""),
                            "startTime": AnyCodable(ISO8601DateFormatter().string(from: eventStartTime)),
                            "location": AnyCodable(availabilityInfo["eventLocation"] as? String ?? "Unknown"),
                        ]
                        
                        let updatedContext: [String: AnyCodable] = [
                            "meetingAvailabilityData": AnyCodable(meetingAvailabilityData)
                        ]
                        
                        print("Debug: Meeting availability data: \(meetingAvailabilityData)")
                        completion(.success(updatedContext))
                    } else {
                        print("Debug: No matching event found")
                        completion(.success([:]))
                    }
                case .failure(let error):
                    print("Debug: Calendar action failed with error: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func handleFlightDataAction(_ action: Action, context: [String: Any], completion: @escaping (Result<[String: AnyCodable], Error>) -> Void) {
        DispatchQueue.global().async {
            guard let flightNumber = action.parameters?["flightNumber"]?.value as? String else {
                completion(.failure(APIError.invalidParameters))
                return
            }
            
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
        
        guard let meetingAvailabilityData = context["meetingAvailabilityData"] as? [String: AnyCodable],
              let eventLocation = meetingAvailabilityData["location"]?.value as? String else {
            print("Error: Missing eventLocation in meetingAvailabilityData")
            completion(.failure(APIError.invalidParameters))
            return
        }
        
        let from = flight.arrivalAirport
        let to = eventLocation
        let arrivalTime = flight.actualArrivalTime ?? flight.arrivalTime
        
        MapsService.shared.getDirections(from: from, to: to, arrivalTime: arrivalTime) { result in
            switch result {
            case .success(let (route, travelTime, sourceCoordinate, destinationCoordinate)):
                let mapData: [String: AnyCodable] = [
                    "fromLocation": AnyCodable(sourceCoordinate),
                    "toLocation": AnyCodable(destinationCoordinate),
                    "travelTime": AnyCodable(travelTime),
                    "route": AnyCodable(route)
                ]
                
                let combinedData: [String: AnyCodable] = [
                    "mapData": AnyCodable(mapData),
                    "meetingAvailabilityData": AnyCodable(meetingAvailabilityData)
                ]
                
                completion(.success(combinedData))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
