//
//  ClothingAdviceService.swift
//  AirSchedule
//
//  Created by Xinyi WU on 10/14/24.
//

import Foundation

class ClothingAdviceService {
    static let shared = ClothingAdviceService()
    private let apiKey = APIKeys.openAIAPIKey
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    
    private init() {}
    
    func suggestAttire(weather: String?, eventType: String?, completion: @escaping (Result<[String: AnyCodable], Error>) -> Void) {
        let prompt = generatePrompt(weather: weather, eventType: eventType)
        
        guard let url = URL(string: endpoint) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let messages: [[String: Any]] = [
            ["role": "system", "content": "You are a helpful assistant that suggests appropriate clothing based on weather conditions and event types."],
            ["role": "user", "content": prompt]
        ]
        
        let parameters: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": messages,
            "max_tokens": 150
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: -1, userInfo: nil)))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let suggestion = message["content"] as? String {
                    let trimmedSuggestion = suggestion.trimmingCharacters(in: .whitespacesAndNewlines)
                    let result: [String: AnyCodable] = [
                        "suggestion": AnyCodable(trimmedSuggestion)
                    ]
                    completion(.success(result))
                } else {
                    completion(.failure(NSError(domain: "Invalid response format", code: -1, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func generatePrompt(weather: String?, eventType: String?) -> String {
        var prompt = "Suggest appropriate clothing for the following conditions:\n"
        if let weather = weather {
            prompt += "Weather: \(weather)\n"
        }
        if let eventType = eventType {
            prompt += "Event type: \(eventType)\n"
        }
        prompt += "Clothing suggestion:"
        return prompt
    }
}
