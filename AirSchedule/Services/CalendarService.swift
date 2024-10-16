//
//  CalendarService.swift
//  AirSchedule
//
//  Created by Xinyi WU on 10/14/24.
//

import Foundation
import EventKit

class CalendarService {
    static let shared = CalendarService()
    private let eventStore = EKEventStore()
    private let llmService = LLMService.shared
    
    private init() {}
    
    /// Checks the authorization status for accessing calendar events.
    /// - Parameter completion: A closure that receives a Boolean indicating whether access is granted.
    func checkAuthorizationStatus(completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { granted, error in
                if let error = error {
                    print("Error requesting full access to events: \(error.localizedDescription)")
                    completion(false)
                } else {
                    completion(granted)
                }
            }
        } else {
            let status = EKEventStore.authorizationStatus(for: .event)
            switch status {
            case .authorized:
                completion(true)
            case .notDetermined:
                requestAccess { granted, _ in
                    completion(granted)
                }
            case .restricted, .denied:
                completion(false)
            @unknown default:
                completion(false)
            }
        }
    }
    
    /// Requests access to calendar events.
    /// - Parameter completion: A closure that receives a Boolean indicating whether access is granted and an optional error.
    private func requestAccess(completion: @escaping (Bool, Error?) -> Void) {
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents(completion: completion)
        } else {
            eventStore.requestAccess(to: .event, completion: completion)
        }
    }
    
    /// Fetches all meetings (events) for a specific date.
    /// - Parameters:
    ///   - date: The date for which to fetch meetings.
    ///   - completion: A closure that receives an array of EKEvent objects or an error.
    func fetchMeetings(for date: Date, completion: @escaping ([EKEvent]?, Error?) -> Void) {
        let calendar = Calendar.current
        guard let startDate = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: date),
              let endDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date) else {
            print("Error: Invalid date range for fetching meetings")
            completion(nil, NSError(domain: "Invalid date", code: -1, userInfo: nil))
            return
        }
        
        print("Fetching meetings for date range: \(startDate) to \(endDate)")
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let events = eventStore.events(matching: predicate)
        print("Found \(events.count) events")
        completion(events, nil)
    }
    
    /// Checks availability by retrieving all events for the day of flight arrival.
    /// - Parameters:
    ///   - flightArrivalTime: The arrival time of the flight.
    ///   - context: The current context to be updated.
    ///   - completion: A closure that receives a Result containing an array of event details or an error.
    func checkAvailability(
        flightArrivalTime: Date,
        context: [String: AnyCodable],
        completion: @escaping (Result<([String: AnyCodable], [[String: AnyCodable]]), Error>) -> Void
    ) {
        print("Checking availability for flight arrival time: \(flightArrivalTime)")
        checkAuthorizationStatus { authorized in
            print("Calendar authorization status: \(authorized)")
            if authorized {
                let flightDate = Calendar.current.startOfDay(for: flightArrivalTime)
                self.fetchMeetings(for: flightDate) { events, error in
                    if let error = error {
                        print("Error fetching meetings: \(error.localizedDescription)")
                        completion(.failure(error))
                        return
                    }
                    
                    guard let events = events, !events.isEmpty else {
                        print("No events found on the day of flight arrival.")
                        completion(.success((context, []))) // Return the current context and an empty array indicating no events
                        return
                    }
                    
                    print("Processing \(events.count) events")
                    // Map EKEvent objects to dictionaries with relevant details
                    let eventDetails = events.map { event -> [String: AnyCodable] in
                        return [
                            "title": AnyCodable(event.title),
                            "location": AnyCodable(event.location ?? "No Location"),
                            "startDate": AnyCodable(event.startDate),
                            "endDate": AnyCodable(event.endDate)
                        ]
                    }
                    
                    print("Availability result: \(eventDetails)")
                    completion(.success((context, eventDetails)))
                }
            } else {
                print("Calendar access not authorized")
                completion(.failure(NSError(domain: "Calendar access not authorized", code: -1, userInfo: nil)))
            }
        }
    }
    
    /// Converts a date string to a Date object using ISO8601 format.
    /// - Parameter dateString: The date string to convert.
    /// - Returns: A Date object if conversion is successful, otherwise nil.
    private func dateFromString(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: dateString)
    }
    

    
    func checkAvailability(event: String?, time: String?, flightArrivalTime: Date, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: flightArrivalTime)
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!

        fetchEvents(from: startDate, to: endDate) { result in
            switch result {
            case .success(let events):
                self.findClosestEventUsingLLM(events: events, query: event ?? "") { result in
                    switch result {
                    case .success(let closestEvent):
                        let isAvailable = closestEvent.startDate > flightArrivalTime
                        let timeDifference = closestEvent.startDate.timeIntervalSince(flightArrivalTime)
                        
                        let availabilityInfo: [String: Any] = [
                            "isAvailable": isAvailable,
                            "event": closestEvent.title,
                            "flightArrivalTime": flightArrivalTime,
                            "eventStartTime": closestEvent.startDate,
                            "timeDifference": timeDifference,
                            "eventLocation": closestEvent.location ?? "Unknown"
                        ]
                        completion(.success(availabilityInfo))
                    case .failure(let error):
                        if (error as NSError).domain == "No matching event" {
                            let availabilityInfo: [String: Any] = [
                                "isAvailable": true,
                                "event": "No matching events found",
                                "flightArrivalTime": flightArrivalTime,
                                "eventStartTime": NSNull(),
                                "timeDifference": NSNull(),
                                "eventLocation": NSNull()
                            ]
                            completion(.success(availabilityInfo))
                        } else {
                            completion(.failure(error))
                        }
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func findClosestEventUsingLLM(events: [EKEvent], query: String, completion: @escaping (Result<EKEvent, Error>) -> Void) {
        if events.isEmpty {
            completion(.failure(NSError(domain: "No events found", code: -1, userInfo: nil)))
            return
        }
        print("Found \(events.count) events")

        let eventsInfo = events.enumerated().map { index, event in
            "[\(index)] Title: \(event.title), Start: \(ISO8601DateFormatter().string(from: event.startDate)), Location: \(event.location ?? "Unknown")"
        }.joined(separator: "\n")

        let prompt = """
        Given the following events and a user query, determine which event is most likely the one the user is referring to. Return ONLY the index number of the best matching event. If no event matches, return -1.

        Events:
        \(eventsInfo)

        User Query: "\(query)"

        Best matching event index:
        """

        llmService.getCompletion(for: prompt) { result in
            switch result {
            case .success(let response):
                if let index = Int(response.trimmingCharacters(in: .whitespacesAndNewlines)),
                   index >= 0 && index < events.count {
                    completion(.success(events[index]))
                    print("Closest event found: \(events[index])")
                } else if let index = Int(response.trimmingCharacters(in: .whitespacesAndNewlines)),
                          index == -1 {
                    completion(.failure(NSError(domain: "No matching event", code: -1, userInfo: nil)))
                } else {
                    completion(.failure(NSError(domain: "Invalid LLM response", code: -1, userInfo: nil)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchEvents(from startDate: Date, to endDate: Date, completion: @escaping (Result<[EKEvent], Error>) -> Void) {
        checkAuthorizationStatus { authorized in
            if authorized {
                let predicate = self.eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
                let events = self.eventStore.events(matching: predicate)
                completion(.success(events))
            } else {
                completion(.failure(NSError(domain: "Calendar access not authorized", code: -1, userInfo: nil)))
            }
        }
    }
}
