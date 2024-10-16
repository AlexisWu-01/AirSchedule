//
//  MapsService.swift
//  AirSchedule
//
//  Created by Xinyi WU on 10/14/24.
//

import Foundation
import MapKit
import CoreLocation


class MapsService {
    static let shared = MapsService()
    private let geocoder = CLGeocoder()
    private let queue = DispatchQueue(label: "com.airschedule.geocoding", attributes: .concurrent)
    
    private init() {}
    
    func getDirections(from: String, to: String, arrivalTime: Date, completion: @escaping (Result<MKRoute, Error>) -> Void) {
        queue.async {
            let group = DispatchGroup()
            var sourceItem: MKMapItem?
            var destinationItem: MKMapItem?
            var geocodingError: Error?
            
            group.enter()
            self.geocodeLocationWithRetry(from, retryCount: 3) { result in
                defer { group.leave() }
                switch result {
                case .success(let mapItem):
                    sourceItem = mapItem
                case .failure(let error):
                    geocodingError = error
                    print("Debug: Geocoding error for 'from' location: \(error.localizedDescription)")
                }
            }
            
            group.enter()
            self.geocodeLocationWithRetry(to, retryCount: 3) { result in
                defer { group.leave() }
                switch result {
                case .success(let mapItem):
                    destinationItem = mapItem
                case .failure(let error):
                    geocodingError = error
                    print("Debug: Geocoding error for 'to' location: \(error.localizedDescription)")
                }
            }
            
            group.notify(queue: .main) {
                if let error = geocodingError {
                    completion(.failure(error))
                    return
                }
                
                guard let source = sourceItem, let destination = destinationItem else {
                    completion(.failure(APIError.invalidResponse(statusCode: 0)))
                    return
                }
                
                let request = MKDirections.Request()
                request.source = source
                request.destination = destination
                request.transportType = .automobile
                request.arrivalDate = arrivalTime
                
                let directions = MKDirections(request: request)
                directions.calculate { response, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    
                    guard let route = response?.routes.first else {
                        completion(.failure(APIError.noData))
                        return
                    }
                    
                    completion(.success(route))
                }
            }
        }
    }
    
    private func geocodeLocationWithRetry(_ location: String, retryCount: Int, completion: @escaping (Result<MKMapItem, Error>) -> Void) {
        print("Debug: Geocoding location: \(location)")
        if location.count == 3 { // Assuming it's an airport code
            getAirportCoordinate(for: location) { result in
                switch result {
                case .success(let coordinate):
                    let placemark = MKPlacemark(coordinate: coordinate)
                    completion(.success(MKMapItem(placemark: placemark)))
                case .failure(let error):
                    print("Debug: Airport coordinate lookup failed: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        } else {
            let cleanedLocation = location.replacingOccurrences(of: "\n", with: ", ")
            print("Debug: Geocoding address: \(cleanedLocation)")
            geocoder.geocodeAddressString(cleanedLocation) { placemarks, error in
                if let error = error {
                    print("Debug: Geocoding error: \(error.localizedDescription)")
                    if retryCount > 0 {
                        print("Debug: Retrying geocoding. Attempts left: \(retryCount - 1)")
                        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
                            self.geocodeLocationWithRetry(location, retryCount: retryCount - 1, completion: completion)
                        }
                    } else {
                        completion(.failure(error))
                    }
                } else if let placemark = placemarks?.first {
                    print("Debug: Geocoding successful")
                    completion(.success(MKMapItem(placemark: MKPlacemark(placemark: placemark))))
                } else {
                    print("Debug: No placemark found")
                    completion(.failure(APIError.noData))
                }
            }
        }
    }
    
    private func getAirportCoordinate(for code: String, completion: @escaping (Result<CLLocationCoordinate2D, Error>) -> Void) {
        let uppercasedCode = code.uppercased()
        let airportCoordinates: [String: CLLocationCoordinate2D] = [
            "SFO": CLLocationCoordinate2D(latitude: 37.6188, longitude: -122.3758),
            "LAX": CLLocationCoordinate2D(latitude: 33.9416, longitude: -118.4085),
            "JFK": CLLocationCoordinate2D(latitude: 40.6413, longitude: -73.7781),
            "SAN": CLLocationCoordinate2D(latitude: 32.7336, longitude: -117.1897),
            // Add more airport codes and coordinates as needed
        ]
        
        if let coordinate = airportCoordinates[uppercasedCode] {
            print("Debug: Found coordinate for airport code \(uppercasedCode)")
            completion(.success(coordinate))
        } else {
            print("Debug: Unknown airport code: \(uppercasedCode)")
            completion(.failure(APIError.invalidParameters))
        }
    }
}
