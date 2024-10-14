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
    
    private init() {}
    
    func requestAccess(completion: @escaping (Bool, Error?) -> Void) {
        eventStore.requestAccess(to: .event) { (granted, error) in
            completion(granted, error)
        }
    }
    
    func fetchEvents(for date: Date, completion: @escaping ([EKEvent]) -> Void) {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: date)
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
        
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let events = eventStore.events(matching: predicate)
        completion(events)
    }
}
