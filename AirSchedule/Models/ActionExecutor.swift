//
//  ActionExecutor.swift
//  AirSchedule
//
//  Created by Xinyi WU on 10/14/24.
//

import Foundation
import MapKit

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
        case "weather":
            handleWeatherAction(action, context: context) { result in
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
        print("Debug: ActionExecutor - handleMapsAction called")
        
        guard let flight = context["flight"] as? Flight,
              let meetingAvailabilityData = context["meetingAvailabilityData"] as? [String: AnyCodable],
              let eventLocation = meetingAvailabilityData["location"]?.value as? String,
              let eventStartTimeString = meetingAvailabilityData["startTime"]?.value as? String,
              let eventStartTime = ISO8601DateFormatter().date(from: eventStartTimeString) else {
            print("Debug: ActionExecutor - Missing or invalid data in context")
            completion(.failure(APIError.invalidParameters))
            return
        }
        
        print("Debug: ActionExecutor - Calling MapsService with from: \(flight.arrivalAirport), to: \(eventLocation)")
        
        MapsService.shared.getDirections(from: flight.arrivalAirport, to: eventLocation, arrivalTime: flight.actualArrivalTime ?? flight.arrivalTime) { result in
            switch result {
            case .success(let (route, fromCoordinate, toCoordinate)):
                print("Debug: ActionExecutor - Received successful result from MapsService")
                print("Debug: ActionExecutor - From coordinate: \(fromCoordinate), To coordinate: \(toCoordinate)")
                
                let mapData: [String: AnyCodable] = [
                    "fromLocation": AnyCodable(["latitude": fromCoordinate.latitude, "longitude": fromCoordinate.longitude]),
                    "toLocation": AnyCodable(["latitude": toCoordinate.latitude, "longitude": toCoordinate.longitude]),
                    "route": AnyCodable(route)
                ]
                
                print("Debug: ActionExecutor - Created mapData: \(mapData)")
                
                var updatedMeetingData = meetingAvailabilityData
                updatedMeetingData["fromCoordinate"] = AnyCodable(["latitude": fromCoordinate.latitude, "longitude": fromCoordinate.longitude])
                updatedMeetingData["toCoordinate"] = AnyCodable(["latitude": toCoordinate.latitude, "longitude": toCoordinate.longitude])
                updatedMeetingData["travelTime"] = AnyCodable(route.expectedTravelTime)
                
                let arrivalTime = flight.actualArrivalTime ?? flight.arrivalTime
                let arrivalPlusTravel = arrivalTime.addingTimeInterval(route.expectedTravelTime + 20*60)
                let canMakeIt = arrivalPlusTravel <= eventStartTime
                updatedMeetingData["canMakeIt"] = AnyCodable(canMakeIt)
                
                var combinedData: [String: AnyCodable] = [
                    "mapData": AnyCodable(mapData),
                    "meetingAvailabilityData": AnyCodable(updatedMeetingData)
                ]
                
                print("Debug: ActionExecutor - Final combinedData: \(combinedData)")
                
                // Create updated UI components
                var updatedUIComponents: [UIComponent] = []
                
                // Add map component
                let mapComponent = UIComponent(type: "map", properties: ["mapData": AnyCodable(mapData)])
                updatedUIComponents.append(mapComponent)
                
                // Add meeting availability component
                let meetingComponent = UIComponent(type: "meetingAvailability", properties: updatedMeetingData)
                updatedUIComponents.append(meetingComponent)
                
                // Add text component for travel time
                let travelTimeMinutes = Int(route.expectedTravelTime / 60) + 20
                let textContent = "The travel time is \(travelTimeMinutes-20) minutes. You \(canMakeIt ? "will" : "might not") be able to make it to the meeting on time."
                let textComponent = UIComponent(type: "text", properties: [
                    "content": AnyCodable(textContent),
                    "travelTime": AnyCodable(travelTimeMinutes),
                    "canMakeIt": AnyCodable(canMakeIt)
                ])
                updatedUIComponents.append(textComponent)

                combinedData["ui_components"] = AnyCodable(updatedUIComponents)

                print("Debug: ActionExecutor - Final combinedData with updated UI components: \(combinedData)")
                
                completion(.success(combinedData))
            case .failure(let error):
                print("Debug: ActionExecutor - Error from MapsService: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    private func getAirportCoordinate(for code: String) -> CLLocationCoordinate2D {
        let airportCoordinates: [String: CLLocationCoordinate2D] = [
            "SFO": CLLocationCoordinate2D(latitude: 37.6188, longitude: -122.3758),
            "LAX": CLLocationCoordinate2D(latitude: 33.9416, longitude: -118.4085),
            "JFK": CLLocationCoordinate2D(latitude: 40.6413, longitude: -73.7781),
            "SAN": CLLocationCoordinate2D(latitude: 32.7336, longitude: -117.1897),
            // Add more airport codes and coordinates as needed
        ]
        
        return airportCoordinates[code] ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }
    
    private func handleWeatherAction(_ action: Action, context: [String: Any], completion: @escaping (Result<[String: AnyCodable], Error>) -> Void) {
        guard let flight = context["flight"] as? Flight else {
            completion(.failure(APIError.invalidParameters))
            return
        }
        
        let location = flight.arrivalAirport
        let time = ISO8601DateFormatter().string(from: flight.actualArrivalTime ?? flight.arrivalTime)
        
        WeatherService.shared.getForecast(location: location, time: time) { result in
            switch result {
            case .success(let weatherData):
                completion(.success(["weatherData": AnyCodable(weatherData)]))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
