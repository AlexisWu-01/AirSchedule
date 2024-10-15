//
//  MapsService.swift
//  AirSchedule
//
//  Created by Xinyi WU on 10/14/24.
//

import Foundation
import MapKit

class MapsService {
    static let shared = MapsService()
    
    private init() {}
    
    func getDirections(from: String, to: String, arrivalTime: Date, completion: @escaping (Result<(MKRoute, TimeInterval, CLLocationCoordinate2D, CLLocationCoordinate2D), Error>) -> Void) {
        print("Debug: Entering getDirections with from: \(from), to: \(to), arrivalTime: \(arrivalTime)")
        let geocoder = CLGeocoder()
        let group = DispatchGroup()
        var sourceCoordinate: CLLocationCoordinate2D?
        var destinationCoordinate: CLLocationCoordinate2D?
        var geocodingError: Error?
        
        group.enter()
        if from.count == 3 { // Assuming it's an airport code
            getAirportCoordinate(for: from) { result in
                defer { group.leave() }
                switch result {
                case .success(let coordinate):
                    sourceCoordinate = coordinate
                    print("Debug: 'From' coordinate (airport): \(String(describing: sourceCoordinate))")
                case .failure(let error):
                    geocodingError = error
                    print("Debug: Error getting airport coordinate: \(error.localizedDescription)")
                }
            }
        } else {
            geocoder.geocodeAddressString(from) { placemarks, error in
                defer { group.leave() }
                if let error = error {
                    print("Debug: Error geocoding 'from' address: \(error.localizedDescription)")
                    geocodingError = error
                    return
                }
                sourceCoordinate = placemarks?.first?.location?.coordinate
                print("Debug: 'From' coordinate: \(String(describing: sourceCoordinate))")
            }
        }
        
        group.enter()
        geocoder.geocodeAddressString(to) { placemarks, error in
            defer { group.leave() }
            if let error = error {
                print("Debug: Error geocoding 'to' address: \(error.localizedDescription)")
                geocodingError = error
                return
            }
            destinationCoordinate = placemarks?.first?.location?.coordinate
            print("Debug: 'To' coordinate: \(String(describing: destinationCoordinate))")
        }
        
        group.notify(queue: .main) {
            if let error = geocodingError {
                print("Debug: Geocoding failed: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let sourceCoordinate = sourceCoordinate, let destinationCoordinate = destinationCoordinate else {
                print("Debug: Invalid coordinates")
                completion(.failure(APIError.invalidResponse(statusCode: 0)))
                return
            }
            
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: sourceCoordinate))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate))
            request.transportType = .automobile
            request.requestsAlternateRoutes = false
            
            let directions = MKDirections(request: request)
            directions.calculate { response, error in
                if let error = error {
                    print("Debug: Error calculating route: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let route = response?.routes.first else {
                    print("Debug: No routes available")
                    completion(.failure(APIError.noData))
                    return
                }
                
                print("Debug: Route calculated successfully. Travel time: \(route.expectedTravelTime)")
                completion(.success((route, route.expectedTravelTime, sourceCoordinate, destinationCoordinate)))
            }
        }
    }
    
    private func getAirportCoordinate(for code: String, completion: @escaping (Result<CLLocationCoordinate2D, Error>) -> Void) {
        // In a real app, you would fetch this from a database or API
        // For this example, we'll hardcode SFO's coordinates
        if code == "SFO" {
            let coordinate = CLLocationCoordinate2D(latitude: 37.6188, longitude: -122.3758)
            completion(.success(coordinate))
        } else {
            completion(.failure(APIError.invalidParameters))
        }
    }
}
