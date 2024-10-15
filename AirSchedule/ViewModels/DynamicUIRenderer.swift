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
        ScrollView {
            VStack(spacing: 20) {
                ForEach(uiComponents, id: \.id) { component in
                    renderComponent(component)
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func renderComponent(_ component: UIComponent) -> some View {
        switch component.type {
        case "text":
            if let text = component.properties["text"]?.value as? String {
                Text(text)
            }
        case "map":
            if let fromLocation = component.properties["fromLocation"]?.value as? CLLocationCoordinate2D,
               let toLocation = component.properties["toLocation"]?.value as? CLLocationCoordinate2D {
                MapView(fromCoordinate: fromLocation, toCoordinate: toLocation)
                    .frame(height: 300)
                    .cornerRadius(10)
            }
        case "error":
            if let errorText = component.properties["text"]?.value as? String {
                Text(errorText)
                    .foregroundColor(.red)
            }
        default:
            EmptyView()
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
