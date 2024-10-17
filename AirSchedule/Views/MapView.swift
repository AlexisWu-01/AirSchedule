import SwiftUI
import MapKit

struct MapLocationView: View {
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
            MapAnnotationItem(coordinate: fromCoordinate, title: "Start"),
            MapAnnotationItem(coordinate: toCoordinate, title: "End")
        ]) { annotation in
            MapMarker(coordinate: annotation.coordinate, tint: annotation.title == "Start" ? .green : .red)
        }
        .frame(height: 300)
        .overlay(
            route.map { route in
                MapOverlay(route: route, region: region)
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
        request.transportType = .automobile // Change as needed

        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let route = response?.routes.first {
                self.route = route
            } else if let error = error {
                print("Error calculating directions: \(error.localizedDescription)")
            }
        }
    }
}

struct MapAnnotationItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
}

struct MapOverlay: View {
    let route: MKRoute
    let region: MKCoordinateRegion

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let mapWidth = geometry.size.width
                let mapHeight = geometry.size.height

                // Calculate the boundaries of the current region
                let minLatitude = region.center.latitude - (region.span.latitudeDelta / 2)
                let maxLatitude = region.center.latitude + (region.span.latitudeDelta / 2)
                let minLongitude = region.center.longitude - (region.span.longitudeDelta / 2)
                let maxLongitude = region.center.longitude + (region.span.longitudeDelta / 2)

                // Function to convert a coordinate to a CGPoint
                func point(for coordinate: CLLocationCoordinate2D) -> CGPoint {
                    let xRatio = (coordinate.longitude - minLongitude) / region.span.longitudeDelta
                    let yRatio = (maxLatitude - coordinate.latitude) / region.span.latitudeDelta
                    return CGPoint(x: CGFloat(xRatio) * mapWidth, y: CGFloat(yRatio) * mapHeight)
                }

                let coordinates = route.polyline.coordinates()
                guard !coordinates.isEmpty else { return }

                path.move(to: point(for: coordinates[0]))
                for coord in coordinates.dropFirst() {
                    path.addLine(to: point(for: coord))
                }
            }
            .stroke(Color.blue, lineWidth: 3)
        }
    }
}

extension MKPolyline {
    func coordinates() -> [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}

struct MapLocationView_Previews: PreviewProvider {
    static var previews: some View {
        MapLocationView(
            fromCoordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // San Francisco
            toCoordinate: CLLocationCoordinate2D(latitude: 37.3382, longitude: -121.8863) // San Jose
        )
    }
}
