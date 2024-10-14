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
        You are an intelligent assistant for a comprehensive travel information app. Your role is to interpret user queries related to flights and associated activities, then generate an actionable plan to address those queries.

        **Available Properties for a Flight Object:**
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

        **CarbonEmissions Struct:**
        - this_flight: Double
        - typical_for_this_route: Double
        - difference_percent: Double

        **Current Flight Details:**

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

        **Available APIs:**
        - **flight_data**: Provides detailed flight information.
        - **calendar**: Manages user schedules and events.
        - **weather**: Offers current and forecasted weather information.
        - **maps**: Supplies navigation and location-based data.
        - **clothing_advice**: Suggests appropriate attire based on weather and event type.

        **Available UI Components:**
        - **text**: Displays textual information.
        - **chart**: Shows data visualizations.
        - **list**: Presents items in a list format.
        - **map**: Displays map views.
        - **image**: Shows images or logos.

        **Objective:**
        Interpret the user's query and generate an action plan in JSON format containing:

        - **"intent"**: The user's primary intent (string).
        - **"entities"**: Relevant entities extracted from the query (object with string key-value pairs).
        - **"actions"**: A list of actions to perform, each containing:
            - **"api"**: (string) The API to interact with (e.g., "flight_data", "weather", "calendar", "maps").
            - **"method"**: (string) The method to invoke on the API.
            - **"parameters"**: (object) Optional parameters required for the method.
        - **"ui_components"**: An array of objects, each with:
            - **"type"**: (string) The type of UI component (e.g., "text", "chart", "list", "map", "image").
            - **"properties"**: (object) Key-value pairs defining the properties of the component.

        **Guidelines:**
        1. **Intent Recognition**:
            - Accurately identify all relevant intents in the user's query.
            - The primary intent should reflect the main purpose of the query, with additional intents captured as necessary.
            - Do not limit intents to flight information only; consider related domains such as scheduling, weather, and navigation.

        2. **Action Planning**:
            - For each identified intent, include corresponding actions using the appropriate APIs.
            - Ensure that actions are necessary and directly related to fulfilling the user's request.
            - Use the provided flight details to populate parameters instead of placeholders.
            - When multiple APIs are required (e.g., weather, calendar, maps), include actions for each relevant API.
            - Avoid redundant API calls; only include what's necessary based on the user's query.

        3. **UI Components**:
            - Design UI components to effectively display the results of the actions.
            - Use suitable types (e.g., "text" for information display, "map" for location data).
            - Combine related information into single components when appropriate (e.g., use a single "text" component for multiple related pieces of information).
            - Ensure UI components correspond logically to the actions and data retrieved.

        4. **Data Typing**:
            - Ensure all returned data is properly typed (string, number, boolean, or date) to facilitate correct UI rendering.

        5. **Response Structure**:
            - Respond only with the JSON data and no additional text.
            - Maintain a clear and consistent JSON structure as specified.

        6. **Avoid Unnecessary Actions**:
            - Do not suggest external API calls unless explicitly prompted by the user's query.
            - Avoid empty "actions" or "ui_components" unless necessary.

        **Example User Queries and Expected Action Plans:**

        ---

        **Example 1: Single Intent**

        **User Query**: "What's the legroom for flight AS 3478?"

        **Expected Action Plan**:
        ```json
        {
        "intent": "get_flight_details",
        "entities": {
            "attribute": "legroom",
            "flightNumber": "AS 3478"
        },
        "actions": [
            {
            "api": "flight_data",
            "method": "getFlightDetails",
            "parameters": {
                "flightNumber": "AS 3478",
                "attribute": "legroom"
            }
            }
        ],
        "ui_components": [
            {
            "type": "text",
            "properties": {
                "content": "The legroom for flight AS 3478 is 30 inches."
            }
            }
        ]
        }

        --- 
        **Example 2: Multiple Intents**

        **User Query**: "Can I make it to my Apple meeting if I take flight AS 3478?"
        **Expected Action Plan**:
        ```json
            {
        "intent": "check_schedule_and_navigation",
        "entities": {
            "event": "Apple meeting",
            "location": "Apple office",
            "time": "2024-10-15T10:00:00Z",
            "flightNumber": "AS 3478"
        },
        "actions": [
            {
            "api": "flight_data",
            "method": "getFlightStatus",
            "parameters": {
                "flightNumber": "AS 3478"
            }
            },
            {
            "api": "calendar",
            "method": "checkAvailability",
            "parameters": {
                "event": "Apple meeting",
                "time": "2024-10-15T10:00:00Z"
            }
            },
            {
            "api": "weather",
            "method": "getForecast",
            "parameters": {
                "location": "Apple office",
                "time": "2024-10-15T10:00:00Z"
            }
            },
            {
            "api": "maps",
            "method": "getDirections",
            "parameters": {
                "from": "arrivalAirport",
                "to": "Apple office",
                "arrivalTime": "2024-10-15T10:00:00Z"
            }
            }
        ],
        "ui_components": [
            {
            "type": "text",
            "properties": {
                "content": "Your flight AS 3478 is on time. You are available for your Apple meeting at 10:00 AM on October 15, 2024. The weather at your destination will be sunny. The estimated travel time from the airport to your meeting location is 30 minutes."
            }
            },
            {
            "type": "map",
            "properties": {
                "from": "arrivalAirport",
                "to": "Apple office",
                "route": "https://maps.example.com/route?from=arrivalAirport&to=Apple+office"
            }
            }
        ]
        }

        ---
        **Example 3: Another Multiple Intents Scenario**

            **User Query**: "What should I wear for my trip if I take this flight?"

            **Expected Action Plan**:
            ```json
        {
        "intent": "clothing_advice_and_weather_forecast",
        "entities": {
            "flightNumber": "AS 3478",
            "destination": "San Francisco",
            "arrivalTime": "2024-10-15T00:20:00Z"
        },
        "actions": [
            {
            "api": "flight_data",
            "method": "getFlightDetails",
            "parameters": {
                "flightNumber": "AS 3478"
            }
            },
            {
            "api": "weather",
            "method": "getForecast",
            "parameters": {
                "location": "San Francisco",
                "time": "2024-10-15T00:20:00Z"
            }
            },
            {
            "api": "clothing_advice",
            "method": "suggestAttire",
            "parameters": {
                "weather": "sunny",
                "eventType": "business trip"
            }
            }
        ],
        "ui_components": [
            {
            "type": "text",
            "properties": {
                "content": "The weather in San Francisco at your arrival time will be sunny. We recommend wearing business casual attire."
            }
            }
        ]
        }
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
