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
        VStack(alignment: .leading, spacing: 10) {
            ForEach(uiComponents, id: \.id) { component in
                componentView(for: component)
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private func componentView(for component: UIComponent) -> some View {
        switch component.type {
        case "text":
            if let content = component.properties["content"]?.value as? String {
                Text(content)
                    .padding()
            }
        case "meetingAvailability":
            meetingAvailabilityView(for: component)
        case "maps", "map":
            if let routeURL = component.properties["route"]?.value as? String,
               let url = URL(string: routeURL) {
                Link("View Route on Map", destination: url)
                    .foregroundColor(.blue)
                    .underline()
                    .padding()
            }
        case "error":
            if let text = component.properties["text"]?.value as? String {
                Text(text)
                    .foregroundColor(.red)
                    .padding()
            }
        case "carbonEmissions":
            if let emissions = component.properties["emissions"]?.value as? CarbonEmissions {
                CarbonEmissionsChartView(emissions: emissions)
            }
        case "map":
            if let from = component.properties["from"]?.value as? String,
               let to = component.properties["to"]?.value as? String {
                MapView(from: from, to: to)
                    .frame(height: 200)
                    .cornerRadius(10)
            } else {
                Text("Error: Invalid map parameters")
                    .foregroundColor(.red)
            }
        default:
            EmptyView()
        }
    }
    
    @ViewBuilder
    private func meetingAvailabilityView(for component: UIComponent) -> some View {
        if let event = component.properties["event"]?.value as? String,
           let flightArrivalTime = component.properties["flightArrivalTime"]?.value as? Date,
           let eventStartTime = component.properties["eventStartTime"]?.value as? Date,
           let canMakeIt = component.properties["canMakeIt"]?.value as? Bool,
           let message = component.properties["message"]?.value as? String,
           let timeDifference = component.properties["timeDifference"]?.value as? TimeInterval,
           let arrivalAirport = component.properties["arrivalAirport"]?.value as? String,
           let eventLocation = component.properties["eventLocation"]?.value as? String {
            
            VStack(alignment: .leading, spacing: 5) {
                Text("Meeting Availability")
                    .font(.headline)
                Text("Event: \(event)")
                Text("Flight Arrival: \(formattedDate(flightArrivalTime)) at \(arrivalAirport)")
                Text("Meeting Start: \(formattedDate(eventStartTime)) at \(eventLocation)")
                Text(message)
                    .font(.body)
                    .foregroundColor(canMakeIt ? .green : .red)
                Text("Time difference: \(formatTimeDifference(timeDifference))")
                
                if let travelTime = component.properties["travelTime"]?.value as? Double {
                    Text("Estimated Travel Time: \(formatTravelTime(travelTime))")
                        .padding(.bottom, 5)
                }
                
                if canMakeIt {
                    if let route = component.properties["route"]?.value as? MKRoute {
                        MapView(from: arrivalAirport, to: eventLocation)
                            .frame(height: 200)
                            .cornerRadius(10)
                    }
                } else {
                    Text("It seems that the meeting would start at \(formattedDate(eventStartTime)) and your flight arrives at \(formattedDate(flightArrivalTime)). With the estimated travel time, you would not be able to make it.")
                        .foregroundColor(.red)
                        .padding(.top, 5)
                }
            }
            .padding()
            .background(canMakeIt ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
            .cornerRadius(10)
        } else {
            Text("Insufficient information to display meeting availability.")
                .foregroundColor(.orange)
                .padding()
        }
    }
    
    // Helper function to format Date to String
    private func formattedDate(_ date: Date) -> String {
        return DateFormatter.shortDateTime.string(from: date)
    }
    
    // Helper function to format TimeInterval to String
    private func formatTimeDifference(_ interval: TimeInterval) -> String {
        let hours = Int(abs(interval)) / 3600
        let minutes = (Int(abs(interval)) % 3600) / 60
        let sign = interval >= 0 ? "+" : "-"
        return "\(sign)\(hours)h \(minutes)m"
    }
    
    // Helper function to format Travel Time (in seconds) to String
    private func formatTravelTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(remainingMinutes)m"
        }
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

struct MeetingAvailabilityView: View {
    let canMakeIt: Bool
    let event: String
    let flightArrivalTime: Date
    let eventStartTime: Date
    let timeDifference: TimeInterval
    let message: String?
    let arrivalAirport: String
    let eventLocation: String
    let travelTime: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Meeting Availability")
                .font(.headline)
            Text("Event: \(event)")
            Text("Flight Arrival: \(formattedDate(flightArrivalTime)) at \(arrivalAirport)")
            Text("Meeting Start: \(formattedDate(eventStartTime)) at \(eventLocation)")
            if let message = message {
                Text(message)
                    .font(.body)
                    .foregroundColor(canMakeIt ? .green : .red)
            } else {
                Text(canMakeIt ? "You can make it to your meeting!" : "You might not make it to your meeting.")
                    .font(.body)
                    .foregroundColor(canMakeIt ? .green : .red)
            }
            Text("Time difference: \(formatTimeDifference(timeDifference))")
            
            // Display Estimated Travel Time if available
            if let travelTime = travelTime {
                Text("Estimated Travel Time: \(travelTime)")
                    .padding(.bottom, 5)
            }
        }
        .padding()
        .background(canMakeIt ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .cornerRadius(10)
    }
    
    // Helper function to format Date to String
    private func formattedDate(_ date: Date) -> String {
        return DateFormatter.shortDateTime.string(from: date)
    }
    
    // Helper function to format TimeInterval to String
    private func formatTimeDifference(_ interval: TimeInterval) -> String {
        let hours = Int(abs(interval)) / 3600
        let minutes = (Int(abs(interval)) % 3600) / 60
        let sign = interval >= 0 ? "+" : "-"
        return "\(sign)\(hours)h \(minutes)m"
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
