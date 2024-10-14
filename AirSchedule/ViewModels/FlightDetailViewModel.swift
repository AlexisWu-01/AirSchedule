import SwiftUI

class FlightDetailViewModel: ObservableObject {
    @Published var flight: Flight
    @Published var dynamicContent: AnyView = AnyView(EmptyView())

    init(flight: Flight) {
        self.flight = flight
    }

    func processUserQuery(_ query: String, completion: @escaping (Bool, Error?) -> Void) {
        LLMService.shared.parseUserQuery(query) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let actionPlan):
                    self?.executeActionPlan(actionPlan) { success, error in
                        completion(success, error)
                    }
                case .failure(let error):
                    print("Error parsing user query: \(error.localizedDescription)")
                    completion(false, error)
                }
            }
        }
    }

    func executeActionPlan(_ actionPlan: ActionPlan, completion: @escaping (Bool, Error?) -> Void) {
        var context = Context()
        let actionGroup = DispatchGroup()

        for action in actionPlan.actions {
            actionGroup.enter()
            executeAction(action, context: context) { result in
                defer { actionGroup.leave() }
                switch result {
                case .success(let updatedContext):
                    context = updatedContext
                case .failure(let error):
                    print("Error executing action \(action.action): \(error.localizedDescription)")
                }
            }
        }

        actionGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.updateUI(with: context.data, components: actionPlan.uiComponents)
            completion(true, nil)
        }
    }

    func executeAction(_ action: Action, context: Context, completion: @escaping (Result<Context, Error>) -> Void) {
        var mutableContext = context
        switch action.action {
        case "get_flight_arrival_time":
            let arrivalTime = flight.arrivalTime
            mutableContext.data["arrival_time"] = arrivalTime
            completion(.success(mutableContext))

        case "get_meeting_details":
            getMeetingDetails { result in
                switch result {
                case .success(let meeting):
                    mutableContext.data["meeting_details"] = meeting
                    completion(.success(mutableContext))
                case .failure(let error):
                    completion(.failure(error))
                }
            }

        case "calculate_travel_time":
            let arrivalAirport = flight.arrivalAirportName
            if let meetingLocation = (mutableContext.data["meeting_details"] as? Meeting)?.location {
                calculateTravelTime(from: arrivalAirport, to: meetingLocation) { result in
                    switch result {
                    case .success(let travelTime):
                        mutableContext.data["travel_time"] = travelTime
                        completion(.success(mutableContext))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            } else {
                completion(.failure(NSError(domain: "Missing data for travel time calculation", code: -1, userInfo: nil)))
            }

        case "determine_availability":
            if let arrivalTime = mutableContext.data["arrival_time"] as? Date,
               let travelTime = mutableContext.data["travel_time"] as? TimeInterval,
               let meeting = mutableContext.data["meeting_details"] as? Meeting {
                let arrivalPlusTravel = arrivalTime.addingTimeInterval(travelTime)
                let timeDifference = meeting.startTime.timeIntervalSince(arrivalPlusTravel)
                let canMakeMeeting = timeDifference >= 0
                mutableContext.data["can_make_meeting"] = canMakeMeeting
                mutableContext.data["time_difference"] = timeDifference
                completion(.success(mutableContext))
            } else {
                completion(.failure(NSError(domain: "Missing data for availability determination", code: -1, userInfo: nil)))
            }

        default:
            print("Unknown action: \(action.action)")
            completion(.failure(NSError(domain: "Unknown action", code: -1, userInfo: nil)))
        }
    }

    func getMeetingDetails(completion: @escaping (Result<Meeting, Error>) -> Void) {
        // Implement actual Calendar API integration here
        // For demonstration, we'll use mock data
        let meeting = Meeting(
            title: "Team Meeting",
            startTime: Date().addingTimeInterval(3600 * 3), // 3 hours from now
            location: "123 Main St, City"
        )
        completion(.success(meeting))
    }

    func calculateTravelTime(from: String, to: String, completion: @escaping (Result<TimeInterval, Error>) -> Void) {
        // Implement actual Maps API integration here
        // For demonstration, we'll use mock data
        let travelTime: TimeInterval = 3600 // 1 hour in seconds
        completion(.success(travelTime))
    }

    func updateUI(with context: [String: Any], components: [String]) {
        if components.contains("meeting_availability_result") {
            if let canMakeMeeting = context["can_make_meeting"] as? Bool,
               let timeDifference = context["time_difference"] as? TimeInterval,
               let meeting = context["meeting_details"] as? Meeting {
                dynamicContent = AnyView(
                    MeetingAvailabilityView(
                        canMakeIt: canMakeMeeting,
                        timeDifference: timeDifference,
                        meeting: meeting
                    )
                )
            } else {
                dynamicContent = AnyView(
                    Text("Unable to determine meeting availability.")
                        .foregroundColor(.red)
                        .padding()
                )
            }
        }

        // Add more UI update logic for other components as needed
    }
}
