//
//  FlightService.swift
//  AirSchedule
//
//  Created by Xinyi WU on 10/13/24.
//
import Foundation



class FlightService {
    static let shared = FlightService()
    private let baseURL = "https://serpapi.com/search?engine=google_flights"
    private let apiKey = APIKeys.serpAPIKey
    private init() {}

    func fetchFlights(from departureAirport: String, to arrivalAirport: String, on date: Date, completion: @escaping (Result<[Flight], Error>) -> Void) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        let urlString = "\(baseURL)&departure_id=\(departureAirport)&arrival_id=\(arrivalAirport)&outbound_date=\(dateString)&api_key=\(apiKey)&type=2" // type=2 is for one-way flights
        guard let url = URL(string: urlString) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let flightResponse = try decoder.decode(SERPFlightResponse.self, from: data)
                let flights = self.processSERPResponse(flightResponse)
                completion(.success(flights))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }

    private func processSERPResponse(_ response: SERPFlightResponse) -> [Flight] {
        var allFlights: [Flight] = []
        
        let processFlightGroup: (FlightGroup) -> Void = { flightGroup in
            for flightData in flightGroup.flights {
                let carbonEmissions = flightGroup.carbon_emissions.map { emissions in
                    CarbonEmissions(
                        this_flight: emissions.this_flight,
                        typical_for_this_route: emissions.typical_for_this_route,
                        difference_percent: emissions.difference_percent
                    )
                }
                
                let scheduledDepartureTime = self.parseDateTime(flightData.departure_airport.time)
                let scheduledArrivalTime = self.parseDateTime(flightData.arrival_airport.time)
                
                // Parse actual times if available, otherwise use scheduled times
                let actualDepartureTime = flightData.departure_airport.actual_time.flatMap(self.parseDateTime) ?? scheduledDepartureTime
                let actualArrivalTime = flightData.arrival_airport.actual_time.flatMap(self.parseDateTime) ?? scheduledArrivalTime
                
                let flight = Flight(
                    airline: flightData.airline,
                    airlineCode: flightData.airline, // Assuming airlineCode is the same as airline name
                    flightNumber: flightData.flight_number,
                    departureTime: scheduledDepartureTime,
                    arrivalTime: scheduledArrivalTime,
                    actualDepartureTime: actualDepartureTime,
                    actualArrivalTime: actualArrivalTime,
                    departureAirport: flightData.departure_airport.id,
                    arrivalAirport: flightData.arrival_airport.id,
                    price: Double(flightGroup.price),
                    departureAirportName: flightData.departure_airport.name,
                    arrivalAirportName: flightData.arrival_airport.name,
                    duration: flightData.duration,
                    airplaneModel: flightData.airplane ?? "Unknown",
                    airlineLogo: flightData.airline_logo ?? "",
                    travelClass: flightData.travel_class ?? "Economy",
                    extensions: flightData.extensions ?? [],
                    legroom: flightData.legroom ?? "Standard",
                    isOvernight: false, // This information is not provided in the FlightData, you may need to calculate it
                    oftenDelayed: flightData.often_delayed_by_over_30_min ?? false,
                    carbonEmissions: carbonEmissions
                )
                allFlights.append(flight)
            }
        }
        
        response.best_flights?.forEach(processFlightGroup)
        response.other_flights?.forEach(processFlightGroup)
        
        return allFlights
    }

    private func parseDateTime(_ dateTimeString: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        return dateFormatter.date(from: dateTimeString) ?? Date()
    }

    func calculateTravelTime(from: String, to: String, completion: @escaping (Result<TimeInterval, Error>) -> Void) {
        // Implement actual Maps API integration here
        // For demonstration, we'll use mock data
        let travelTime: TimeInterval = 3600 // 1 hour in seconds
        completion(.success(travelTime))
    }
}

enum APIError: Error {
    case invalidURL
    case invalidResponse(statusCode: Int)
    case noData
    case unknownAPI
    case invalidParameters
}
