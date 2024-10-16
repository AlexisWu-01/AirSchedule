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
                ForEach(uiComponents) { component in
                    renderComponent(component)
                }
                Spacer()
            }
            .padding()
            .onAppear {
                print("Debug: DynamicUIRenderer appeared with \(uiComponents.count) components")
                for (index, component) in uiComponents.enumerated() {
                    print("Debug: Component \(index) - Type: \(component.type), Properties: \(component.properties)")
                }
            }
        }
    }
    
    @ViewBuilder
    private func renderComponent(_ component: UIComponent) -> some View {
        switch component.type {
        case "meetingAvailability":
            ImprovedMeetingAvailabilityView(meetingData: component.properties)
        case "map":
            if let mapData = component.properties["mapData"]?.value as? [String: AnyCodable],
               let fromLocation = mapData["fromLocation"]?.value as? CLLocationCoordinate2D,
               let toLocation = mapData["toLocation"]?.value as? CLLocationCoordinate2D {
                MapLocationView(fromCoordinate: fromLocation, toCoordinate: toLocation)
            } else {
                ImprovedTextView(content: "Invalid map data")
            }
        case "text":
            if let content = component.properties["content"]?.value as? String {
                ImprovedTextView(content: content)
            } else {
                ImprovedTextView(content: "Invalid text data")
            }
        case "weather":
            if let weatherData = component.properties["weatherData"]?.value as? [String: AnyCodable] {
                ImprovedWeatherView(weatherData: weatherData)
            } else {
                ImprovedTextView(content: "Invalid weather data")
            }
        default:
            ImprovedTextView(content: "Unsupported component type: \(component.type)")
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
        let weatherData: [String: AnyCodable]
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("Weather at \(weatherData["location"]?.value as? String ?? "Unknown")")
                    .font(.headline)
                HStack {
                    Image(systemName: weatherIcon)
                        .font(.largeTitle)
                    VStack(alignment: .leading) {
                        Text(weatherData["weather"]?.value as? String ?? "Unknown")
                            .font(.subheadline)
                        if let time = weatherData["time"]?.value as? String {
                            Text("Time: \(time)")
                                .font(.caption)
                        }
                    }
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
        }
        
        private var weatherIcon: String {
            switch weatherData["weather"]?.value as? String {
            case "Sunny": return "sun.max.fill"
            case "Cloudy": return "cloud.fill"
            case "Rainy": return "cloud.rain.fill"
            case "Windy": return "wind"
            default: return "questionmark.circle.fill"
            }
        }
    }
}



struct ImprovedTextView: View {
    let content: String
    
    var body: some View {
        Text(content)
            .font(.body)
            .foregroundColor(.primary)
            .padding()
            .background(Color.airLightBlue)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct ImprovedMeetingAvailabilityView: View {
    let meetingData: [String: AnyCodable]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(meetingData["title"]?.value as? String ?? "Unknown Event")
                .font(.headline)
                .foregroundColor(.airBlue)
            
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.airDarkGray)
                Text(formattedTime(meetingData["startTime"]?.value as? String))
                    .font(.subheadline)
            }
            
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(.airDarkGray)
                Text(meetingData["location"]?.value as? String ?? "Unknown Location")
                    .font(.subheadline)
            }
            
            if let canMakeIt = meetingData["canMakeIt"]?.value as? Bool {
                HStack {
                    Image(systemName: canMakeIt ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(canMakeIt ? .green : .red)
                    Text(canMakeIt ? "You can make it to the meeting" : "You might not make it to the meeting")
                        .font(.subheadline)
                        .foregroundColor(canMakeIt ? .green : .red)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func formattedTime(_ isoString: String?) -> String {
        guard let isoString = isoString,
              let date = ISO8601DateFormatter().date(from: isoString) else {
            return "Unknown Time"
        }
        return DateFormatter.shortDateTime.string(from: date)
    }
}

struct ImprovedWeatherView: View {
    let weatherData: [String: AnyCodable]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Weather at Arrival")
                .font(.headline)
            
            HStack {
                Image(systemName: weatherIcon)
                    .font(.system(size: 40))
                    .foregroundColor(.airBlue)
                
                VStack(alignment: .leading) {
                    Text(weatherData["weather"]?.value as? String ?? "Unknown")
                        .font(.title2)
                    if let temperature = weatherData["temperature"]?.value as? Int {
                        Text("\(temperature)°F")
                            .font(.title3)
                            .foregroundColor(.airBlue)
                    }
                    Text(weatherData["location"]?.value as? String ?? "Unknown Location")
                        .font(.subheadline)
                    Text(formattedTime(weatherData["time"]?.value as? String ?? ""))
                        .font(.subheadline)
                        .foregroundColor(.airDarkGray)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var weatherIcon: String {
        switch weatherData["weather"]?.value as? String {
        case "Sunny": return "sun.max.fill"
        case "Cloudy": return "cloud.fill"
        case "Rainy": return "cloud.rain.fill"
        case "Windy": return "wind"
        default: return "questionmark.circle.fill"
        }
    }
    
    private func formattedTime(_ time: String) -> String {
        let inputFormatter = ISO8601DateFormatter()
        inputFormatter.formatOptions = [.withInternetDateTime]
        
        if let date = inputFormatter.date(from: time) {
            return DateFormatter.shortDateTime.string(from: date)
        }
        return time
    }
}
