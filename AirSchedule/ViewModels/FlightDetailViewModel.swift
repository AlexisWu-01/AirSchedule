//
//  FlightDetailViewModel.swift
//  AirSchedule
//
//  Created by Xinyi WU on 10/14/24.
//

import SwiftUI
import Combine

class FlightDetailViewModel: ObservableObject {
    @Published var flight: Flight
    @Published var uiComponents: [UIComponent] = []
    @Published var context: [String: AnyCodable] = [:]

    init(flight: Flight) {
        self.flight = flight
        self.context = ["flight": AnyCodable(flight)]
    }
    
    private func updateUI() {
        DispatchQueue.main.async {
            print("Debug: Updating UI with \(self.uiComponents.count) components")
            for (index, component) in self.uiComponents.enumerated() {
                print("Debug: Component \(index) - Type: \(component.type)")
            }
            print("Debug: DynamicContent updated")
        }
    }

    func processUserQuery(_ query: String, completion: @escaping (Bool, Error?) -> Void) {
        LLMService.shared.parseUserQuery(query, forFlight: flight) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let actionPlan):
                self.executeActionPlan(actionPlan, completion: completion)
            case .failure(let error):
                print("Error parsing user query: \(error.localizedDescription)")
                if let decodingError = error as? DecodingError {
                    print("Decoding error: \(decodingError)")
                }
                completion(false, error)
            }
        }
    }

    private func handleLLMError(_ error: Error) {
        let errorComponent = UIComponent(type: "error", properties: ["text": AnyCodable(error.localizedDescription)])
        DispatchQueue.main.async {
            self.uiComponents = [errorComponent]
        }
    }

    func executeActionPlan(_ actionPlan: ActionPlan, completion: @escaping (Bool, Error?) -> Void) {
        var contextAny: [String: Any] = ["flight": flight]
        DispatchQueue.main.async {
            self.uiComponents = actionPlan.uiComponents ?? []
            self.updateUI()
        }
        executeActionsSequentially(actions: actionPlan.actions ?? [], index: 0, context: contextAny) { success, error, updatedContext in
            DispatchQueue.main.async {
                self.context = updatedContext.mapValues { AnyCodable($0) }
                self.updateUI()
                completion(success, error)
            }
        }
    }

    private func executeActionsSequentially(actions: [Action], index: Int, context: [String: Any], completion: @escaping (Bool, Error?, [String: Any]) -> Void) {
        if index >= actions.count {
            completion(true, nil, context)
            return
        }
        
        let action = actions[index]
        print("Processing action: API=\(action.api), Method=\(action.method)")
        
        ActionExecutor.shared.executeAction(action, context: context) { [weak self] result in
            guard let self = self else {
                completion(false, NSError(domain: "Self is nil", code: -1, userInfo: nil), context)
                return
            }
            
            switch result {
            case .success(let updatedContext):
                var newContext = context
                for (key, value) in updatedContext {
                    newContext[key] = value.value
                }
                DispatchQueue.main.async {
                    self.context = updatedContext
                }
                // Proceed to the next action
                self.executeActionsSequentially(actions: actions, index: index + 1, context: newContext, completion: completion)
                
            case .failure(let error):
                print("Error executing action: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.uiComponents.append(UIComponent(type: "error", properties: ["text": AnyCodable(error.localizedDescription)]))
                }
                completion(false, error, context)
            }
        }
    }

    private func formatTravelTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(remainingMinutes)m"
        }
    }

    private func formatTimeDifference(_ interval: TimeInterval) -> String {
        let hours = Int(abs(interval)) / 3600
        let minutes = (Int(abs(interval)) % 3600) / 60
        let sign = interval >= 0 ? "+" : "-"
        return "\(sign)\(hours)h \(minutes)m"
    }

}