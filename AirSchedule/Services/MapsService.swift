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
    
    func getDirections(from: String, to: String, arrivalTime: Date, completion: @escaping (Result<(MKRoute, TimeInterval), Error>) -> Void) {
        print("Debug: Entering getDirections with from: \(from), to: \(to), arrivalTime: \(arrivalTime)")
        let geocoder = CLGeocoder()
        let group = DispatchGroup()
        var sourceCoordinate: CLLocationCoordinate2D?
        var destinationCoordinate: CLLocationCoordinate2D?
        var geocodingError: Error?
        
        group.enter()
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
                completion(.success((route, route.expectedTravelTime)))
            }
        }
    }
}
