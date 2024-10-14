import SwiftUI

struct DynamicUIRenderer: View {
    let components: [UIComponent]
    let context: [String: Any]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(components, id: \.id) { component in
                renderComponent(component)
            }
        }
    }
    
    @ViewBuilder
    private func renderComponent(_ component: UIComponent) -> some View {
        switch component.type {
        case "text":
            if let content = component.properties["content"]?.value as? String ?? component.properties["text"]?.value as? String {
                Text(content)
                    .padding(.vertical, 5)
            }
        case "error":
            if let text = component.properties["text"]?.value as? String {
                Text(text)
                    .foregroundColor(.red)
                    .padding(.vertical, 5)
            }
        case "Message":
            if let text = component.properties["text"]?.value as? String {
                Text(text)
                    .italic()
                    .padding(.vertical, 5)
            }
        default:
            Text("Unsupported component type: \(component.type)")
                .foregroundColor(.orange)
                .padding(.vertical, 5)
        }
    }
}

extension DateFormatter {
    static let shortDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
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
                    Text("\(emissions.this_flight)g")
                    Text("\(emissions.typical_for_this_route)g")
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Meeting Availability")
                .font(.headline)
            Text(canMakeIt ? "You can make it to your meeting on time." : "You might be late for your meeting.")
                .font(.body)
                .foregroundColor(canMakeIt ? .green : .red)
        }
        .padding()
        .background(canMakeIt ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .cornerRadius(10)
    }
}

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
