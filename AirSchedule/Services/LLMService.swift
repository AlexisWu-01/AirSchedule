//
//  LLMService.swift
//  AirSchedule
//
//  Created by Xinyi WU on 10/14/24.
//
import Foundation

class LLMService {
    static let shared = LLMService()
    private let apiKey = APIKeys.openAIAPIKey

    private init() {}

    func parseUserQuery(_ query: String, forFlight flight: Flight, completion: @escaping (Result<ActionPlan, Error>) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let systemMessage = """
        You are an assistant for a flight information app. Here are the available properties for a Flight object:

        - flightNumber: String
        - airline: String
        - airlineLogo: URL
        - departureAirport: String
        - departureAirportName: String
        - arrivalAirport: String
        - arrivalAirportName: String
        - departureTime: Date
        - actualDepartureTime: Date?
        - arrivalTime: Date
        - actualArrivalTime: Date?
        - price: Double
        - duration: Int
        - airplaneModel: String
        - travelClass: String
        - legroom: String
        - isOvernight: Bool
        - oftenDelayed: Bool
        - carbonEmissions: CarbonEmissions?

        CarbonEmissions struct:

        - this_flight: Double
        - typical_for_this_route: Double
        - difference_percent: Double

        Current Flight Details:

        
        \(flight.flightNumber.map { "- flightNumber: \($0)" }.joined(separator: "\n"))
        \(flight.airline.map { "- airline: \($0)" }.joined(separator: "\n"))
        \(flight.airlineLogo.map { "- airlineLogo: \($0)" }.joined(separator: "\n"))
        \(flight.departureAirport.map { "- departureAirport: \($0)" }.joined(separator: "\n"))
        \(flight.departureAirportName.map { "- departureAirportName: \($0)" }.joined(separator: "\n"))
        \(flight.arrivalAirport.map { "- arrivalAirport: \($0)" }.joined(separator: "\n"))
        \(flight.arrivalAirportName.map { "- arrivalAirportName: \($0)" }.joined(separator: "\n"))
        "- departureTime: \(flight.departureTime)"
        "- actualDepartureTime: \(flight.actualDepartureTime ?? flight.departureTime)"
        "- arrivalTime: \(flight.arrivalTime)"
        "- actualArrivalTime: \(flight.actualArrivalTime ?? flight.arrivalTime)"
        "- price: \(flight.price)"
        "- duration: \(flight.duration)"
        "- airplaneModel: \(flight.airplaneModel)"
        "- travelClass: \(flight.travelClass)"
        "- legroom: \(flight.legroom)"
        "- isOvernight: \(flight.isOvernight)"
        "- oftenDelayed: \(flight.oftenDelayed)"

        \(flight.carbonEmissions.map { emissions in
            """
            - carbonEmissions:
                - this_flight: \(emissions.this_flight)
                - typical_for_this_route: \(emissions.typical_for_this_route)
                - difference_percent: \(emissions.difference_percent)
            """
        } ?? "")

        Interpret the user's query and generate an action plan in JSON format containing:

        - "intent": The user's intent (string).
        - "entities": Relevant entities extracted from the query (object with string key-value pairs).
        - "actions": A list of actions to perform, each containing:
            - "api": (string) The API to interact with (e.g., "flight_data", "weather", "calendar").
            - "method": (string) The method to invoke on the API.
            - "parameters": (object) Optional parameters required for the method.
        - "ui_components": An array of objects, each with:
            - "type": (string) The type of UI component (e.g., "text", "chart", "list").
            - "properties": (object) Key-value pairs defining the properties of the component.

        **Guidelines:**
        - Ensure that for every user intent requiring data retrieval or computation, corresponding actions are included.
        - UI components should be present to display the results of these actions.
        - Avoid returning empty "actions" or "ui_components" when the user query necessitates a response.
        - Do not suggest external API calls without being prompted by the user's query.
        - Use the provided flight details to populate parameters instead of using placeholders like "unknown".
        - For simple flight information queries, directly provide the information from the Current Flight Details in the "entities" field without creating actions.
        - When answering queries that require multiple pieces of information, use sentence-based responses in a single "text" type UI component, rather than multiple separate components.
        - Ensure that all returned data is properly typed (string, number, boolean, or date) to allow for correct UI rendering.
        - Always include a "type" field for each UI component in the "ui_components" array. Use generic types like "text", "chart", or "list".
        - For flight information queries, including carbon emissions, use the "flight_info" intent and provide the information directly in the ui_components without creating actions.
        - Only use actions when additional data retrieval or computation is necessary beyond the provided flight details.
        - Prefer natural language responses in the "text" property of ui_components for all flight-related queries.
        
        Respond only with the JSON data and no additional text.
        """

        let userMessage = "User Query: \"\(query)\"\n\nAction Plan:"

        let messages: [[String: String]] = [
            ["role": "system", "content": systemMessage],
            ["role": "user", "content": userMessage]
        ]

        let body: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": messages,
            "max_tokens": 500,
            "temperature": 0
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("Error serializing JSON: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error during API call: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            guard let data = data else {
                print("No data received from API.")
                completion(.failure(NSError(domain: "No data", code: -1, userInfo: nil)))
                return
            }

            do {
                let decoder = JSONDecoder()
                let apiResponse = try decoder.decode(ChatCompletionResponse.self, from: data)
                if let content = apiResponse.choices.first?.message.content {
                    let cleanedResponse = content.trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: "```json\n", with: "")
                        .replacingOccurrences(of: "\n```", with: "")
                    
                    print("Cleaned Response: \(cleanedResponse)")
                    
                    if let responseData = cleanedResponse.data(using: .utf8) {
                        let actionPlan = try decoder.decode(ActionPlan.self, from: responseData)
                        completion(.success(actionPlan))
                    } else {
                        print("Failed to convert cleanedResponse to Data")
                        completion(.failure(NSError(domain: "Invalid response data", code: -1, userInfo: nil)))
                    }
                } else {
                    print("No content in API response")
                    completion(.failure(NSError(domain: "No content", code: -1, userInfo: nil)))
                }
            } catch {
                print("Error decoding API response: \(error)")
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .typeMismatch(let type, let context):
                        print("Type mismatch: expected \(type) at \(context.codingPath)")
                    case .valueNotFound(let type, let context):
                        print("Value not found: expected \(type) at \(context.codingPath)")
                    case .keyNotFound(let key, let context):
                        print("Key not found: \(key) at \(context.codingPath)")
                    case .dataCorrupted(let context):
                        print("Data corrupted: \(context)")
                    @unknown default:
                        print("Unknown decoding error")
                    }
                }
                completion(.failure(error))
            }
        }

        task.resume()
    }
}

// Supporting Models

struct ChatCompletionResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: Message
}

struct Message: Codable {
    let role: String
    let content: String
}
