import SwiftUI

class FlightDetailViewModel: ObservableObject {
    @Published var flight: Flight
    @Published var dynamicContent: AnyView = AnyView(EmptyView())
    @Published var uiComponents: [UIComponent] = []
    @Published var context: [String: Any] = [:]

    init(flight: Flight) {
        self.flight = flight
    }

    func processUserQuery(_ query: String, completion: @escaping (Bool, Error?) -> Void) {
        LLMService.shared.parseUserQuery(query, forFlight: flight) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let actionPlan):
                    self?.executeActionPlan(actionPlan, completion: completion)
                case .failure(let error):
                    print("Error parsing user query: \(error.localizedDescription)")
                    self?.handleLLMError(error)
                    completion(false, error)
                }
            }
        }
    }

    func handleLLMError(_ error: Error) {
        let errorComponent = UIComponent(type: "error", properties: ["text": AnyCodable(error.localizedDescription)])
        self.uiComponents = [errorComponent]
        self.updateUI()
    }

    func executeActionPlan(_ actionPlan: ActionPlan, completion: @escaping (Bool, Error?) -> Void) {
        context = ["flight": flight] // Set the flight in the context
        uiComponents = [] // Reset UI components

        // Handle direct flight information retrieval or complex actions
        if actionPlan.actions == nil || actionPlan.actions!.isEmpty {
            self.uiComponents = actionPlan.uiComponents
            self.updateUI()
            completion(true, nil)
            return
        }

        let actionGroup = DispatchGroup()

        // Handle complex actions
        for action in actionPlan.actions! {
            print("Processing action: API=\(action.api), Method=\(action.method)")
            actionGroup.enter()
            ActionExecutor.shared.executeAction(action, context: &context) { result in
                switch result {
                case .success(let updatedContext):
                    self.context.merge(updatedContext) { (_, new) in new }
                    print("Action executed successfully. Updated context: \(updatedContext)")
                case .failure(let error):
                    print("Error executing action: \(error.localizedDescription)")
                    self.uiComponents.append(UIComponent(type: "error", properties: ["text": AnyCodable(error.localizedDescription)]))
                }
                actionGroup.leave()
            }
        }

        actionGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            if self.uiComponents.isEmpty {
                if !actionPlan.uiComponents.isEmpty {
                    self.uiComponents = actionPlan.uiComponents
                } else {
                    let newComponents = self.generateUIComponents(from: self.context)
                    if !newComponents.isEmpty {
                        self.uiComponents = newComponents
                    } else {
                        let defaultComponent = UIComponent(type: "text", properties: ["content": AnyCodable("No information available.")])
                        self.uiComponents = [defaultComponent]
                    }
                }
            }
            print("Updating UI with components: \(self.uiComponents)")
            self.updateUI()
            completion(true, nil)
        }
    }

    private func generateUIComponents(from context: [String: Any]) -> [UIComponent] {
        var components: [UIComponent] = []

        if let content = context["content"] as? String {
            components.append(UIComponent(type: "text", properties: ["content": AnyCodable(content)]))
        }

        if let carbonEmissions = context["this_flight"] as? Int,
           let typicalEmissions = context["typical_for_this_route"] as? Int,
           let differencePercent = context["difference_percent"] as? Int {
            let text = """
            Carbon Emissions:
            - This Flight: \(carbonEmissions) kg CO2
            - Typical for this Route: \(typicalEmissions) kg CO2
            - Difference: \(differencePercent)%
            """
            components.append(UIComponent(type: "text", properties: ["content": AnyCodable(text)]))
        }

        return components
    }

    func updateUI() {
        DispatchQueue.main.async {
            self.dynamicContent = AnyView(
                DynamicUIRenderer(components: self.uiComponents, context: self.context)
            )
            self.objectWillChange.send()
        }
    }
}
