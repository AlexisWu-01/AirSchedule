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

    func parseUserQuery(_ query: String, completion: @escaping (Result<ActionPlan, Error>) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let systemMessage = """
        You are an assistant for a flight information app. Interpret the user's query and generate an action plan in JSON format containing:

        - "intent": The user's intent.
        - "entities": Relevant entities extracted from the query.
        - "actions": A list of actions to perform, specifying the APIs or methods to call.
        - "ui_components": Suggestions for UI elements to display.

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

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print("HTTP Error: \(httpResponse.statusCode)")
                if let data = data, let errorResponse = String(data: data, encoding: .utf8) {
                    print("API Error Response: \(errorResponse)")
                }
                let statusError = NSError(domain: "HTTP Error", code: httpResponse.statusCode, userInfo: nil)
                completion(.failure(statusError))
                return
            }

            guard let data = data else {
                print("No data received from API")
                completion(.failure(NSError(domain: "No data", code: -1, userInfo: nil)))
                return
            }

            do {
                // Decode the API response into ChatAPIResponse
                let decoder = JSONDecoder()
                let apiResponse = try decoder.decode(ChatAPIResponse.self, from: data)

                // Extract the generated content from the message
                if let content = apiResponse.choices.first?.message.content {
                    // Clean up the response text
                    let cleanedResponse = content.trimmingCharacters(in: .whitespacesAndNewlines)
                    // Convert the cleaned text into Data
                    if let responseData = cleanedResponse.data(using: .utf8) {
                        // Decode the ActionPlan from the responseData
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
                print("Error decoding API response: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }

        task.resume()
    }
}

// Structs for the Chat Completion API response
struct ChatAPIResponse: Codable {
    let choices: [ChatChoice]
}

struct ChatChoice: Codable {
    let message: ChatMessage
}

struct ChatMessage: Codable {
    let role: String
    let content: String
}
