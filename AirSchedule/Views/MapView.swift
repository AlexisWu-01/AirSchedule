//
//  MapView.swift
//  AirSchedule
//
//  Created by Xinyi WU on 10/14/24.
//

import SwiftUI
import MapKit

struct PolylineOverlay: Shape {
    let route: MKRoute
    
    func path(in rect: CGRect) -> Path {
        let polyline = route.polyline
        let path = Path { path in
            for index in 0..<polyline.pointCount {
                let polyPoint = polyline.points()[index]
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

struct MapView: View {
    @State private var region: MKCoordinateRegion
    @State private var route: MKRoute?
    @State private var travelTime: TimeInterval?
    @State private var annotations: [CustomAnnotation] = []
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""
    
    let fromCoordinate: CLLocationCoordinate2D
    let toCoordinate: CLLocationCoordinate2D
    
    init(fromCoordinate: CLLocationCoordinate2D, toCoordinate: CLLocationCoordinate2D) {
            self.fromCoordinate = fromCoordinate
            self.toCoordinate = toCoordinate
            _region = State(initialValue: MKCoordinateRegion(
                center: fromCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            ))
        }

        var body: some View {
            Map(coordinateRegion: $region)
                .frame(height: 300)
                .cornerRadius(10)
                .onAppear {
                    print("MapView appeared with from: \(fromCoordinate) to: \(toCoordinate)")
                }
        }
    
    private func calculateRoute() {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: fromCoordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: toCoordinate))
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let error = error {
                self.routeCalculationFailed(error: error)
                return
            }
            guard let route = response?.routes.first else {
                self.routeCalculationFailed(message: "No routes available.")
                return
            }
            
            DispatchQueue.main.async {
                self.route = route
                self.travelTime = route.expectedTravelTime
                self.region = MKCoordinateRegion(route.polyline.boundingMapRect)
                self.annotations = [
                    CustomAnnotation(coordinate: self.fromCoordinate, color: .red),
                    CustomAnnotation(coordinate: self.toCoordinate, color: .green)
                ]
            }
            DispatchQueue.main.async {
                self.route = route
                self.travelTime = route.expectedTravelTime
                self.annotations = [
                    CustomAnnotation(coordinate: fromCoordinate, color: .red),
                    CustomAnnotation(coordinate: toCoordinate, color: .green)
                ]
                print("Debug: State updated with route and annotations.")
            }

        }
    }
    
    private func routeCalculationFailed(error: Error? = nil, message: String? = nil) {
        DispatchQueue.main.async {
            let errorMessage = error?.localizedDescription ?? message ?? "Route calculation failed."
            print("Route calculation failed: \(errorMessage)")
            self.errorMessage = errorMessage
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

// Custom Annotation Struct
struct CustomAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let color: Color
}
