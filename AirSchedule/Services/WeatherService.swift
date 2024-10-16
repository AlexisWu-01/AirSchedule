//
//  WeatherService.swift
//  AirSchedule
//
//  Created by Xinyi WU on 10/14/24.
//

import Foundation

class WeatherService {
    static let shared = WeatherService()
    
    private init() {}
    
    func getForecast(location: String?, time: String?, completion: @escaping (Result<[String: AnyCodable], Error>) -> Void) {
        // Simulated weather forecast
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            let weatherConditions = ["Sunny", "Cloudy", "Rainy", "Windy"]
            let randomWeather = weatherConditions.randomElement() ?? "Unknown"
            let randomTemperature = Int.random(in: 50...90)
            let result: [String: AnyCodable] = [
                "weather": AnyCodable(randomWeather),
                "location": AnyCodable(location ?? ""),
                "time": AnyCodable(time ?? ""),
                "temperature": AnyCodable(randomTemperature)
            ]
            completion(.success(result))
        }
    }
}
