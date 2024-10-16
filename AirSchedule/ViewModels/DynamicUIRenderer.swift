//
//  DynamicUIRenderer.swift
//  AirSchedule
//
//  Created by Xinyi WU on 10/14/24.
//

import SwiftUI
import MapKit

// Move the DateFormatter extension to the file scope
extension DateFormatter {
    static let shortDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

struct DynamicUIRenderer: View {
    let uiComponents: [UIComponent]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Debug: DynamicUIRenderer with \(uiComponents.count) components")
                .foregroundColor(.red)
            
            ForEach(uiComponents.indices, id: \.self) { index in
                renderComponent(uiComponents[index], index: index)
            }
        }
        .padding()
        .onAppear {
            print("Debug: DynamicUIRenderer appeared with \(uiComponents.count) components")
            for (index, component) in uiComponents.enumerated() {
                print("Debug: Component \(index) - Type: \(component.type)")
            }
        }
    }
    
    @ViewBuilder
    private func renderComponent(_ component: UIComponent, index: Int) -> some View {
        switch component.type {
        case "text":
            if let content = component.properties["content"]?.value as? String {
                Text(content)
                    .onAppear { print("Debug: Rendering text component \(index): \(content)") }
            } else if let canMakeIt = component.properties["canMakeIt"]?.value as? Bool,
                      let message = component.properties["message"]?.value as? String {
                Text(message)
                    .foregroundColor(canMakeIt ? .green : .red)
                    .onAppear { print("Debug: Rendering text component \(index): \(message)") }
            } else {
                Text("Invalid text component")
                    .foregroundColor(.red)
                    .onAppear { print("Debug: Invalid text component \(index)") }
            }
        case "map":
            if let from = component.properties["from"]?.value as? String,
               let to = component.properties["to"]?.value as? String {
                Text("Map from \(from) to \(to)")
                    .onAppear { print("Debug: Rendering map component \(index)") }
            } else {
                Text("Invalid map component")
                    .foregroundColor(.red)
                    .onAppear { print("Debug: Invalid map component: Missing or invalid coordinates.") }
            }
        case "error":
            if let errorText = component.properties["text"]?.value as? String {
                Text(errorText)
                    .foregroundColor(.red)
                    .onAppear { print("Debug: Rendering error component \(index): \(errorText)") }
            }
        case "meetingAvailability":
            if let meetingData = component.properties as? [String: AnyCodable] {
                MeetingAvailabilityView(meetingData: meetingData)
                    .onAppear { print("Debug: Rendering meeting availability component with data: \(meetingData)") }
            } else {
                Text("No meeting data available")
                    .foregroundColor(.gray)
                    .onAppear { print("Debug: No meeting data available. Raw data: \(component.properties)") }
            }
        default:
            Text("Unknown component type: \(component.type)")
                .foregroundColor(.orange)
                .onAppear { print("Debug: Unknown component type \(index): \(component.type)") }
        }
    }
    
    
    // Example UI Components
    
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
    
    
    
    // Weather View
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
