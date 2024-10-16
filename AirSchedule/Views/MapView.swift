//
//  MapView.swift
//  AirSchedule
//
//  Created by Xinyi Wu on 2024-10-14.
//

import SwiftUI
import MapKit

struct CustomMapView: View {
    let route: MKRoute
    let sourceCoordinate: CLLocationCoordinate2D
    let destinationCoordinate: CLLocationCoordinate2D
    
    @State private var region: MKCoordinateRegion
    @State private var annotations: [MapAnnotation]
    
    init(route: MKRoute, sourceCoordinate: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D) {
        self.route = route
        self.sourceCoordinate = sourceCoordinate
        self.destinationCoordinate = destinationCoordinate
        
        let center = CLLocationCoordinate2D(
            latitude: (sourceCoordinate.latitude + destinationCoordinate.latitude) / 2,
            longitude: (sourceCoordinate.longitude + destinationCoordinate.longitude) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: abs(sourceCoordinate.latitude - destinationCoordinate.latitude) * 1.5,
            longitudeDelta: abs(sourceCoordinate.longitude - destinationCoordinate.longitude) * 1.5
        )
        _region = State(initialValue: MKCoordinateRegion(center: center, span: span))
        
        _annotations = State(initialValue: [
            MapAnnotation(coordinate: sourceCoordinate, title: "Start"),
            MapAnnotation(coordinate: destinationCoordinate, title: "End")
        ])
    }
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: annotations) { annotation in
            MapMarker(coordinate: annotation.coordinate, tint: annotation.title == "Start" ? .green : .red)
        }
        .overlay(
            MapOverlay(route: route)
        )
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
        CustomMapView(
            route: MKRoute(),
            sourceCoordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            destinationCoordinate: CLLocationCoordinate2D(latitude: 37.3382, longitude: -121.8863)
        )
    }
}
