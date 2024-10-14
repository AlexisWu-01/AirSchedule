import SwiftUI

class FlightDetailViewModel: ObservableObject {
    @Published var flight: Flight
    @Published var dynamicContent: AnyView = AnyView(EmptyView())
    @Published var uiComponents: [String] = []
    @Published var context: [String: Any] = [:]

    init(flight: Flight) {
        self.flight = flight
    }

    func processUserQuery(_ query: String, completion: @escaping (Bool, Error?) -> Void) {
        LLMService.shared.parseUserQuery(query) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let actionPlan):
                    self?.executeActionPlan(actionPlan, completion: completion)
                case .failure(let error):
                    print("Error parsing user query: \(error.localizedDescription)")
                    completion(false, error)
                }
            }
        }
    }

    func executeActionPlan(_ actionPlan: ActionPlan, completion: @escaping (Bool, Error?) -> Void) {
        context = [:] // Reset context for new action plan
        let group = DispatchGroup()

        for action in actionPlan.actions {
            group.enter()
            executeAction(action) { result in
                switch result {
                case .success:
                    group.leave()
                case .failure(let error):
                    print("Error executing action: \(error.localizedDescription)")
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.uiComponents = actionPlan.uiComponents
            self.updateUI()
            completion(true, nil)
        }
    }

    func executeAction(_ action: Action, completion: @escaping (Result<Void, Error>) -> Void) {
        switch action.api {
        case "get_flight_arrival_time":
            let arrivalTime = flight.arrivalTime
            context["arrival_time"] = arrivalTime
            completion(.success(()))
        case "get_meeting_details":
            // Implement this method to fetch meeting details
            // For now, we'll use mock data
            let meetingTime = Date().addingTimeInterval(3600 * 3) // 3 hours from now
            context["meeting_time"] = meetingTime
            completion(.success(()))
        case "calculate_travel_time":
            // Implement this method to calculate travel time
            // For now, we'll use a mock value
            context["travel_time"] = 1800 // 30 minutes in seconds
            completion(.success(()))
        case "determine_availability":
            if let arrivalTime = context["arrival_time"] as? Date,
               let meetingTime = context["meeting_time"] as? Date,
               let travelTime = context["travel_time"] as? TimeInterval {
                let canMakeMeeting = arrivalTime.addingTimeInterval(travelTime) <= meetingTime
                context["can_make_meeting"] = canMakeMeeting
                completion(.success(()))
            } else {
                completion(.failure(NSError(domain: "Missing context data", code: -1, userInfo: nil)))
            }
        default:
            completion(.failure(NSError(domain: "Unknown action", code: -1, userInfo: nil)))
        }
    }

    func updateUI() {
        DispatchQueue.main.async {
            self.dynamicContent = AnyView(
                DynamicUIRenderer(components: self.uiComponents, context: self.context)
            )
        }
    }
}
