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
    
    func getDirections(from: String, to: String, arrivalTime: Date, completion: @escaping (Result<(MKRoute, CLLocationCoordinate2D, CLLocationCoordinate2D), Error>) -> Void) {
        print("Debug: MapsService - getDirections called with from: \(from), to: \(to)")
        queue.async {
            let group = DispatchGroup()
            var sourceCoordinate: CLLocationCoordinate2D?
            var destinationCoordinate: CLLocationCoordinate2D?
            var geocodingError: Error?
            
            group.enter()
            self.geocodeLocation(from) { result in
                defer { group.leave() }
                switch result {
                case .success(let coordinate):
                    sourceCoordinate = coordinate
                case .failure(let error):
                    geocodingError = error
                    print("Debug: Geocoding error for 'from' location: \(error.localizedDescription)")
                }
            }
            
            group.enter()
            self.geocodeLocation(to) { result in
                defer { group.leave() }
                switch result {
                case .success(let coordinate):
                    destinationCoordinate = coordinate
                case .failure(let error):
                    geocodingError = error
                    print("Debug: Geocoding error for 'to' location: \(error.localizedDescription)")
                }
            }
            
            group.notify(queue: .main) {
                if let error = geocodingError {
                    print("Debug: MapsService - Geocoding error: \(error)")
                    completion(.failure(error))
                    return
                }
                
                guard let source = sourceCoordinate, let destination = destinationCoordinate else {
                    print("Debug: MapsService - Invalid coordinates")
                    completion(.failure(APIError.invalidResponse(statusCode: 0)))
                    return
                }
                
                print("Debug: MapsService - Coordinates obtained - From: \(source), To: \(destination)")
                
                let request = MKDirections.Request()
                request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
                request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
                request.transportType = .automobile
                request.arrivalDate = arrivalTime
                
                let directions = MKDirections(request: request)
                directions.calculate { response, error in
                    if let error = error {
                        print("Debug: MapsService - Directions calculation error: \(error)")
                        completion(.failure(error))
                        return
                    }
                    
                    guard let route = response?.routes.first else {
                        print("Debug: MapsService - No route found")
                        completion(.failure(APIError.noData))
                        return
                    }
                    
                    print("Debug: MapsService - Route calculated successfully")
                    completion(.success((route, source, destination)))
                }
            }
        }
    }
    
    private func geocodeLocation(_ location: String, completion: @escaping (Result<CLLocationCoordinate2D, Error>) -> Void) {
        if location.count == 3 { // Assuming it's an airport code
            if let coordinate = getAirportCoordinate(for: location) {
                completion(.success(coordinate))
            } else {
                completion(.failure(APIError.invalidParameters))
            }
        } else {
            let cleanedLocation = location.replacingOccurrences(of: "\n", with: ", ")
            geocoder.geocodeAddressString(cleanedLocation) { placemarks, error in
                if let error = error {
                    completion(.failure(error))
                } else if let placemark = placemarks?.first, let coordinate = placemark.location?.coordinate {
                    completion(.success(coordinate))
                } else {
                    completion(.failure(APIError.noData))
                }
            }
        }
    }
    
    private func getAirportCoordinate(for code: String) -> CLLocationCoordinate2D? {
        let airportCoordinates: [String: CLLocationCoordinate2D] = [
            "SFO": CLLocationCoordinate2D(latitude: 37.6188, longitude: -122.3758),
            "LAX": CLLocationCoordinate2D(latitude: 33.9416, longitude: -118.4085),
            "JFK": CLLocationCoordinate2D(latitude: 40.6413, longitude: -73.7781),
            "SAN": CLLocationCoordinate2D(latitude: 32.7336, longitude: -117.1897),
            // Add more airport codes and coordinates as needed
        ]
        
        return airportCoordinates[code.uppercased()]
    }
}
