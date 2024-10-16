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

            "- flightNumber: \(flight.flightNumber)"
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
            - **meetingAvailability**: Displays meeting availability information with flight details.

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
                - Prioritize intents based on their relevance and dependency.

            2. **Action Planning**:
                - For each identified intent, include corresponding actions using the appropriate APIs.
                - Ensure that actions are necessary and directly related to fulfilling the user's request.
                - Use the provided flight details from the context to populate parameters instead of extracting from the query.
                - When multiple APIs are required (e.g., weather, calendar, maps), include actions for each relevant API.
                - Ensure dependent actions are ordered correctly (e.g., fetch meeting details before calculating travel time).
                - Avoid redundant API calls; only include what's necessary based on the user's query.
                - **Do not use placeholders** in the action parameters. Instead, reference context keys that will be replaced with actual data during execution.

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
                - Give complete flight number: for example, when the flight number is AS 3478, do not just give A.

            7. **Accuracy**:
                - Always use known accurate flight information when it is related to flight.
                - Validate extracted entities against available data to ensure correctness.

            8. **Error Handling**:
                - If essential information is missing or cannot be retrieved, structure the action plan to request the necessary data or inform the user appropriately.

            **Example User Queries and Expected Action Plans:**

            ---

            **Example 1: Single Intent**

            **User Query**: "What's the legroom for flight AS3478?"

            **Expected Action Plan**:
            ```json
            {
            "intent": "get_flight_details",
            "entities": {
                "attribute": "legroom",
                "flightNumber": "AS3478"
            },
            "actions": [
                {
                "api": "flight_data",
                "method": "getFlightDetails",
                "parameters": {
                    "flightNumber": "AS3478",
                    "attribute": "legroom"
                }
                }
            ],
            "ui_components": [
                {
                "type": "text",
                "properties": {
                    "content": "The legroom for flight AS3478 is 30 inches."
                }
                }
            ]
            }
            ```

            --- 

            **Example 2: Multiple Intents with Correct Logic**

            **User Query**: "Can I make it to my apple meeting?"

            **Expected Action Plan**:
            ```json
            {
            "intent": "check_schedule_and_navigation",
            "entities": {
                "event": "apple meeting"
            },
            "actions": [
                {
                "api": "calendar",
                "method": "getEventDetails",
                "parameters": {
                    "event": "apple meeting"
                }
                },
                {
                "api": "flight_data",
                "method": "getFlightStatus",
                "parameters": {
                    "flightNumber": "AS3478"
                }
                },
                {
                "api": "maps",
                "method": "getDirections",
                "parameters": {
                    "from": "arrivalAirport", // To be dynamically replaced with actual arrival airport code from flight_data
                    "to": "eventLocation", // To be dynamically replaced with actual meeting location from calendar
                    "arrivalTime": "actualArrivalTime" // To be dynamically replaced with actual arrival time from flight_data
                }
                }
            ],
            "ui_components": [
            {
            type": "meetingAvailability",
                "properties": {
                "title": "Apple Meeting",
                "time": "2024-10-15T15:30:00Z",
                "location": "Apple Park, Cupertino, CA"
                }
                },
                {
                "type": "text",
                "properties": {
                    "canMakeIt": true, // Dynamically set based on calendar and map data
                    "message": "You can make it to your apple meeting on time."
                }
                },
                {
                "type": "map",
                "properties": {
                    "from": "arrivalAirport",
                    "to": "eventLocation",
                }
                }
            ]
            }
            ```

            **Logic Flow:**
            1. **Retrieve Meeting Details:** Use the `calendar` API to get the meeting's time and location.
            2. **Check Flight Status:** Use the `flight_data` API to get the actual arrival time of flight AS3478.
            3. **Calculate Travel Time:** Use the `maps` API to determine the travel time from the arrival airport to the meeting location based on the arrival time.
            4. **Determine Feasibility:** Compare the travel time with the time remaining until the meeting to decide if the user can make it on time.
            5. **UI Components:** Display a message indicating whether the user can make it and show the route on a map.

            ---

            **Example 3: Another Multiple Intents Scenario**

            **User Query**: "What should I wear for my trip if I take flight AS3478?"

            **Expected Action Plan**:
            ```json
            {
            "intent": "clothing_advice_and_weather_forecast",
            "entities": {
                "flightNumber": "AS3478",
                "destination": "San Francisco",
                "arrivalTime": "2024-10-15T00:20:00Z"
            },
            "actions": [
                {
                "api": "flight_data",
                "method": "getFlightDetails",
                "parameters": {
                    "flightNumber": "AS3478"
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
                    "weather": "sunny", // To be dynamically set based on weather API response
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
            ```
            ---

            **Example 4: Simplified Flight Carbon Emissions Inquiry**

            **User Query**: "What are the carbon emissions for flight AS3478?"

            **Expected Action Plan**:
            ```json
            {
            "intent": "get_carbon_emissions",
            "entities": {
                "flightNumber": "AS3478"
            },
            "actions": [
                {
                "api": "flight_data",
                "method": "getCarbonEmissions",
                "parameters": {
                    "flightNumber": "AS3478"
                }
                }
            ],
            "ui_components": [
                {
                "type": "text",
                "properties": {
                    "content": "Flight AS3478 emits 120.5 kg of CO₂."
                }
                }
            ]
            }
            ```
            ---
            
            **Example 5: Weather and Calendar Integration**

            **User Query**: "Do I need an umbrella for my conference next Monday?"

            **Expected Action Plan**:
            ```json
            {
            "intent": "weather_forecast_and_event_preparation",
            "entities": {
                "event": "conference",
                "date": "2024-10-21"
            },
            "actions": [
                {
                "api": "calendar",
                "method": "getEventDetails",
                "parameters": {
                    "event": "conference",
                    "date": "2024-10-21"
                }
                },
                {
                "api": "weather",
                "method": "getForecast",
                "parameters": {
                    "location": "conferenceLocation", // To be dynamically set based on calendar response
                    "time": "2024-10-21T09:00:00Z" // To be dynamically set based on event time
                }
                },
                {
                "api": "clothing_advice",
                "method": "suggestAccessories",
                "parameters": {
                    "weather": "rainy", // To be dynamically set based on weather API response
                    "eventType": "conference"
                }
                }
            ],
            "ui_components": [
                {
                "type": "text",
                "properties": {
                    "content": "The forecast for your conference in New York on 2024-10-21 is rainy. We recommend bringing an umbrella."
                }
                },
                {
                "type": "image",
                "properties": {
                    "url": "https://example.com/umbrella.png",
                    "description": "Umbrella Recommendation"
                }
                }
            ]
            }
            ```

            **Logic Flow:**
            1. **Retrieve Conference Details:** Use the `calendar` API to get the conference's location and time.
            2. **Check Weather Forecast:** Use the `weather` API to get the forecast for the conference location and time.
            3. **Provide Accessories Advice:** Use the `clothing_advice` API to suggest whether an umbrella is needed based on the weather.
            4. **UI Components:** Display a message about the weather forecast and show an image of an umbrella if recommended.
            ---
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
                    
                    let cleanedJSONString = self.removeCommentsFromJSON(cleanedResponse)
                    let actionPlan = try JSONDecoder().decode(ActionPlan.self, from: Data(cleanedJSONString.utf8))
                    completion(.success(actionPlan))
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

    // Add this method to the LLMService class

    func getCompletion(for prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let messages: [[String: String]] = [
            ["role": "system", "content": "You are a helpful assistant."],
            ["role": "user", "content": prompt]
        ]
        
        let body: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": messages,
            "max_tokens": 10,
            "temperature": 0
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: -1, userInfo: nil)))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let apiResponse = try decoder.decode(ChatCompletionResponse.self, from: data)
                if let content = apiResponse.choices.first?.message.content {
                    completion(.success(content))
                } else {
                    completion(.failure(NSError(domain: "No content", code: -1, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }

    private func removeCommentsFromJSON(_ jsonString: String) -> String {
        let pattern = "//.*?\\n|/\\*.*?\\*/"
        let regex = try! NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
        let range = NSRange(jsonString.startIndex..., in: jsonString)
        return regex.stringByReplacingMatches(in: jsonString, options: [], range: range, withTemplate: "")
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
