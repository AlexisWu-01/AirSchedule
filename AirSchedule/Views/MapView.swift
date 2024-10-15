//
//  MapView.swift
//  AirSchedule
//
//  Created by Xinyi WU on 10/14/24.
//

import SwiftUI
import MapKit

struct MapView: View {
    let from: String
    let to: String
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var route: MKRoute?
    @State private var travelTime: TimeInterval?
    @State private var annotations: [MapAnnotation] = []
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        VStack {
            ZStack {
                Map(coordinateRegion: $region, annotationItems: annotations) { annotation in
                    MapMarker(coordinate: annotation.coordinate, tint: annotation.color)
                }
                .overlay {
                    if let route = route {
                        PolylineOverlay(route: route)
                            .stroke(Color.blue, lineWidth: 3)
                    }
                }
                .frame(height: 300)
                .cornerRadius(10)
                
                if route == nil && annotations.count == 2 {
                    ProgressView("Calculating Route...")
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(8)
                }
            }
            .padding()
            
            if let travelTime = travelTime {
                Text("Estimated Travel Time: \(formatTravelTime(travelTime))")
                    .padding(.top, 5)
            }
        }
        .onAppear {
            print("MapView appeared with from: '\(from)', to: '\(to)'")
            calculateRoute()
        }
        .alert(isPresented: $showingError) {
            Alert(title: Text("Error"),
                  message: Text(errorMessage),
                  dismissButton: .default(Text("OK")))
        }
    }
    
    private func calculateRoute() {
        print("Calculating route from '\(from)' to '\(to)'")
        let geocoder = CLGeocoder()
        let group = DispatchGroup()
        
        var fromLocation: CLLocationCoordinate2D?
        var toLocation: CLLocationCoordinate2D?
        
        DispatchQueue.main.async {
            self.annotations.removeAll()
            self.route = nil
            self.travelTime = nil
        }
        
        group.enter()
        geocoder.geocodeAddressString(from) { placemarks, error in
            defer { group.leave() }
            if let error = error {
                print("Error geocoding 'from' address: \(error.localizedDescription)")
                self.geocodingFailed(error: error)
                return
            }
            
            guard let placemark = placemarks?.first, let location = placemark.location else {
                print("Failed to find location for 'from' address")
                self.geocodingFailed(message: "Origin address not found.")
                return
            }
            
            fromLocation = location.coordinate
            print("Successfully geocoded 'from' address: \(location.coordinate)")
            DispatchQueue.main.async {
                self.annotations.append(MapAnnotation(coordinate: location.coordinate, color: .red))
            }
        }
        
        group.enter()
        geocoder.geocodeAddressString(to) { placemarks, error in
            defer { group.leave() }
            if let error = error {
                print("Error geocoding 'to' address: \(error.localizedDescription)")
                self.geocodingFailed(error: error)
                return
            }
            
            guard let placemark = placemarks?.first, let location = placemark.location else {
                print("Failed to find location for 'to' address")
                self.geocodingFailed(message: "Destination address not found.")
                return
            }
            
            toLocation = location.coordinate
            print("Successfully geocoded 'to' address: \(location.coordinate)")
            DispatchQueue.main.async {
                self.annotations.append(MapAnnotation(coordinate: location.coordinate, color: .green))
            }
        }
        
        group.notify(queue: .main) {
            guard let from = fromLocation, let to = toLocation else {
                print("Unable to retrieve both locations.")
                self.geocodingFailed(message: "Failed to retrieve both locations.")
                return
            }
            
            print("Calculating route between \(from) and \(to)")
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: from))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: to))
            request.transportType = .automobile
            request.requestsAlternateRoutes = false
            
            let directions = MKDirections(request: request)
            directions.calculate { response, error in
                if let error = error {
                    print("Error calculating route: \(error.localizedDescription)")
                    self.routeCalculationFailed(error: error)
                    return
                }
                
                guard let route = response?.routes.first else {
                    print("No routes available between the selected locations.")
                    self.routeCalculationFailed(message: "No routes available between the selected locations.")
                    return
                }
                
                print("Route calculated successfully. Travel time: \(route.expectedTravelTime) seconds")
                self.route = route
                self.travelTime = route.expectedTravelTime
                self.region = MKCoordinateRegion(route.polyline.boundingMapRect)
            }
        }
    }
    
    private func geocodingFailed(error: Error? = nil, message: String? = nil) {
        DispatchQueue.main.async {
            self.errorMessage = error?.localizedDescription ?? message ?? "Geocoding failed."
            self.showingError = true
        }
    }
    
    private func routeCalculationFailed(error: Error? = nil, message: String? = nil) {
        DispatchQueue.main.async {
            self.errorMessage = error?.localizedDescription ?? message ?? "Route calculation failed."
            self.showingError = true
        }
    }
    
    private func formatTravelTime(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: seconds) ?? ""
    }
}

// Custom Overlay for Polyline
struct PolylineOverlay: Shape {
    let route: MKRoute
    
    func path(in rect: CGRect) -> Path {
        let polyline = route.polyline
        let path = Path { path in
            for index in 0..<polyline.pointCount {
                let polyPoint = polyline.points()[index] // Renamed to 'polyPoint' to avoid duplicate
                let coord = polyPoint.coordinate
                let mapPoint = MKMapPoint(coord)
                let mapRect = polyline.boundingMapRect
                let x = CGFloat((mapPoint.x - mapRect.origin.x) / mapRect.size.width) * rect.width
                let y = CGFloat((mapPoint.y - mapRect.origin.y) / mapRect.size.height) * rect.height
                let point = CGPoint(x: x, y: y)
                
                if index == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
        }
        return path
    }
}

// Custom Annotation Struct
struct MapAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let color: Color
}
