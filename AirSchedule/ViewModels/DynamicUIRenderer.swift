//
//  DynamicUIRenderer.swift
//  AirSchedule
//
//  Created by Xinyi WU on 10/14/24.
//

import SwiftUI
import MapKit



// MARK: - DateFormatter Extension
extension DateFormatter {
    static let shortDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - DynamicUIRenderer View
struct DynamicUIRenderer: View {
    let uiComponents: [UIComponent]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Debug: DynamicUIRenderer with \(uiComponents.count) components")
                    .foregroundColor(.red)
                    .padding(.top)
                
                ForEach(uiComponents) { component in
                    renderComponent(component)
                }
                
                Spacer()
            }
            .padding()
            .onAppear {
                print("Debug: DynamicUIRenderer appeared with \(uiComponents.count) components")
                for (index, component) in uiComponents.enumerated() {
                    print("Debug: Component \(index) - Type: \(component.type)")
                }
            }
        }
    }
    
    @ViewBuilder
    private func renderComponent(_ component: UIComponent) -> some View {
        switch component.type {
        case "meetingAvailability":
            MeetingAvailabilityView(meetingData: component.properties)
        case "map":
            if let mapData = component.properties["mapData"]?.value as? [String: AnyCodable],
               let fromLocation = mapData["fromLocation"]?.value as? CLLocationCoordinate2D,
               let toLocation = mapData["toLocation"]?.value as? CLLocationCoordinate2D {
                MapLocationView(fromCoordinate: fromLocation, toCoordinate: toLocation)
                    .onAppear {
                        print("Debug: Rendering map component from \(fromLocation) to \(toLocation)")
                    }
            } else {
                Text("Invalid map data")
                    .onAppear {
                        print("Debug: Invalid map data in component: \(component.properties)")
                    }
            }
        case "text":
            if let content = component.properties["content"]?.value as? String {
                Text(content)
                    .onAppear {
                        print("Debug: Rendering text component: \(content)")
                    }
            } else {
                Text("Invalid text data")
                    .onAppear {
                        print("Debug: Invalid text data in component: \(component.properties)")
                    }
            }
        default:
            Text("Unsupported component type: \(component.type)")
                .onAppear {
                    print("Debug: Unsupported component type: \(component.type)")
                }
        }
    }
    
    // MARK: - Example UI Components (Optional)
    struct LegroomStatusView: View {
        let legroom: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: 5) {
                Text("Legroom Information")
                    .font(.headline)
                Text(legroom)
                    .font(.body)
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(10)
        }
    }
    
    struct CarbonEmissionsChartView: View {
        let emissions: CarbonEmissions
        
        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                Text("Carbon Emissions")
                    .font(.headline)
                HStack {
                    VStack(alignment: .leading) {
                        Text("This Flight:")
                        Text("Typical for Route:")
                        Text("Difference:")
                    }
                    VStack(alignment: .trailing) {
                        Text("\(emissions.this_flight) kg")
                        Text("\(emissions.typical_for_this_route) kg")
                        Text("\(emissions.difference_percent)%")
                            .foregroundColor(emissions.difference_percent < 0 ? .green : .red)
                    }
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Weather View
    struct WeatherView: View {
        let weatherDescription: String
        
        var body: some View {
            HStack {
                Image(systemName: "sun.max.fill")
                    .foregroundColor(.yellow)
                Text("Weather: \(weatherDescription)")
                    .font(.body)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

// MARK: - MapLocationView with MapOverlay Integration
struct MapLocationView: View {
    let fromCoordinate: CLLocationCoordinate2D
    let toCoordinate: CLLocationCoordinate2D
    @State private var route: MKRoute?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var travelTime: TimeInterval?

    var body: some View {
        ZStack {
            if let route = route {
                CustomMapView(route: route, sourceCoordinate: fromCoordinate, destinationCoordinate: toCoordinate)
            } else {
                Map(coordinateRegion: .constant(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(
                        latitude: (fromCoordinate.latitude + toCoordinate.latitude) / 2,
                        longitude: (fromCoordinate.longitude + toCoordinate.longitude) / 2
                    ),
                    span: MKCoordinateSpan(
                        latitudeDelta: abs(fromCoordinate.latitude - toCoordinate.latitude) * 1.5,
                        longitudeDelta: abs(fromCoordinate.longitude - toCoordinate.longitude) * 1.5
                    )
                )), annotationItems: [
                    MapAnnotation(coordinate: fromCoordinate, title: "Start"),
                    MapAnnotation(coordinate: toCoordinate, title: "End")
                ]) { annotation in
                    MapMarker(coordinate: annotation.coordinate, tint: annotation.title == "Start" ? .green : .red)
                }
            }
            if isLoading {
                ProgressView()
            }
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
        }
        .frame(height: 300)
        .cornerRadius(10)
        .onAppear(perform: loadRoute)
    }

    private func loadRoute() {
        print("Debug: Starting loadRoute")
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: fromCoordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: toCoordinate))
        request.transportType = .automobile

        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    print("Debug: Error loading route - \(error.localizedDescription)")
                } else if let route = response?.routes.first {
                    print("Debug: Successfully loaded route")
                    self.route = route
                    self.travelTime = route.expectedTravelTime
                } else {
                    self.errorMessage = "No route found"
                    print("Debug: No route found")
                }
            }
        }
    }
}



