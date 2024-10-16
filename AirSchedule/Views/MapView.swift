//
//  MapView.swift
//  AirSchedule
//
//  Created by Xinyi Wu on 2024-10-14.
//

import SwiftUI
import MapKit

struct MapLocationView: View {
    let id = UUID()
    let fromCoordinate: CLLocationCoordinate2D
    let toCoordinate: CLLocationCoordinate2D
    @State private var route: MKRoute?
    @State private var region: MKCoordinateRegion
    
    init(fromCoordinate: CLLocationCoordinate2D, toCoordinate: CLLocationCoordinate2D) {
        self.fromCoordinate = fromCoordinate
        self.toCoordinate = toCoordinate
        let center = CLLocationCoordinate2D(
            latitude: (fromCoordinate.latitude + toCoordinate.latitude) / 2,
            longitude: (fromCoordinate.longitude + toCoordinate.longitude) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: abs(fromCoordinate.latitude - toCoordinate.latitude) * 1.5,
            longitudeDelta: abs(fromCoordinate.longitude - toCoordinate.longitude) * 1.5
        )
        _region = State(initialValue: MKCoordinateRegion(center: center, span: span))
    }
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: [
            MapAnnotation(coordinate: fromCoordinate, title: "Start"),
            MapAnnotation(coordinate: toCoordinate, title: "End")
        ]) { annotation in
            MapMarker(coordinate: annotation.coordinate, tint: annotation.title == "Start" ? .green : .red)
        }
        .frame(height: 300)
        .overlay(
            route.map { route in
                MapOverlay(route: route)
            }
        )
        .onAppear {
            calculateRoute()
        }
    }
    
    private func calculateRoute() {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: fromCoordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: toCoordinate))
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let route = response?.routes.first {
                self.route = route
            }
        }
    }
}

struct MapAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
}

struct MapOverlay: View {
    let route: MKRoute
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                var isFirst = true
                for coordinate in route.polyline.coordinates() {
                    let point = geometry.coordinateToPoint(coordinate)
                    if isFirst {
                        path.move(to: point)
                        isFirst = false
                    } else {
                        path.addLine(to: point)
                    }
                }
            }
            .stroke(Color.blue, lineWidth: 3)
        }
    }
}

extension GeometryProxy {
    func coordinateToPoint(_ coordinate: CLLocationCoordinate2D) -> CGPoint {
        let frame = self.frame(in: .global)
        let regionWidth = frame.width / (frame.height / 256)
        let longitudeRatio = (coordinate.longitude + 180) / 360
        let latitudeRatio = (coordinate.latitude + 90) / 180
        return CGPoint(
            x: frame.width * CGFloat(longitudeRatio),
            y: frame.height * CGFloat(1 - latitudeRatio)
        )
    }
}

extension MKPolyline {
    func coordinates() -> [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}

struct CustomMapView_Previews: PreviewProvider {
    static var previews: some View {
        MapLocationView(
            fromCoordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            toCoordinate: CLLocationCoordinate2D(latitude: 37.3382, longitude: -121.8863)
        )
    }
}
