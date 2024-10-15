import SwiftUI

class FlightDetailViewModel: ObservableObject {
    @Published var flight: Flight
    @Published var dynamicContent: AnyView = AnyView(EmptyView())
    @Published var uiComponents: [UIComponent] = []
    @Published var context: [String: AnyCodable] = [:]

    init(flight: Flight) {
        self.flight = flight
        self.context = ["flight": AnyCodable(flight)]
    }
    
    private func updateUI() {
        dynamicContent = AnyView(DynamicUIRenderer(uiComponents: uiComponents))
    }

    /// Processes the user's query by parsing it and executing the resulting action plan.
    /// - Parameters:
    ///   - query: The user's natural language query.
    ///   - completion: Completion handler indicating success or failure.
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

    /// Handles errors encountered during LLM parsing.
    /// - Parameter error: The error to handle.
    private func handleLLMError(_ error: Error) {
        let errorComponent = UIComponent(type: "error", properties: ["text": AnyCodable(error.localizedDescription)])
        self.uiComponents = [errorComponent]
        self.updateUI()
    }

    private func executeActionPlan(_ actionPlan: ActionPlan, completion: @escaping (Bool, Error?) -> Void) {
        var contextAny: [String: Any] = ["flight": flight]
        uiComponents = actionPlan.uiComponents ?? []
        let actionGroup = DispatchGroup()

        for action in actionPlan.actions ?? [] {
            print("Processing action: API=\(action.api), Method=\(action.method)")
            actionGroup.enter()
            ActionExecutor.shared.executeAction(action, context: contextAny) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let updatedContext):
                    DispatchQueue.main.async {
                        // Update the context with the new information
                        for (key, value) in updatedContext {
                            self.context[key] = value
                            contextAny[key] = value.value
                        }
                        // ... rest of your existing code ...
                    }
                case .failure(let error):
                    print("Error executing action: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.uiComponents.append(UIComponent(type: "error", properties: ["text": AnyCodable(error.localizedDescription)]))
                        self.updateUI()
                    }
                }
                actionGroup.leave()
            }
        }

        actionGroup.notify(queue: .main) {
            print("Updating UI with components: \(self.uiComponents)")
            self.updateUI()
            completion(true, nil)
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
