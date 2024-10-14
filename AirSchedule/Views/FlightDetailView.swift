// FlightDetailView.swift

import SwiftUI

struct FlightDetailView: View {
    @ObservedObject var viewModel: FlightDetailViewModel
    @State private var userQuery: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Flight Header
                HStack {
                    AsyncImage(url: URL(string: viewModel.flight.airlineLogo)) { image in
                        image.resizable()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 50, height: 50)
                    
                    Text("\(viewModel.flight.airline) Flight \(viewModel.flight.flightNumber)")
                        .font(.title)
                }
                
                // Essential Flight Information
                Group {
                    infoRow("Departure", "\(viewModel.flight.departureAirportName) (\(viewModel.flight.departureAirport))")
                    infoRow("Arrival", "\(viewModel.flight.arrivalAirportName) (\(viewModel.flight.arrivalAirport))")
                    infoRow("Date", formattedDate(viewModel.flight.departureTime))
                    infoRow("Scheduled Departure", formattedTime(viewModel.flight.departureTime))
                    infoRow("Actual Departure", formattedTime(viewModel.flight.actualDepartureTime ?? viewModel.flight.departureTime))
                    infoRow("Scheduled Arrival", formattedTime(viewModel.flight.arrivalTime))
                    infoRow("Actual Arrival", formattedTime(viewModel.flight.actualArrivalTime ?? viewModel.flight.arrivalTime))
                    infoRow("Price", "$\(String(format: "%.2f", viewModel.flight.price))")
                    infoRow("Duration", formatDuration(TimeInterval(viewModel.flight.duration)))
                    infoRow("Airplane Model", viewModel.flight.airplaneModel)
                    infoRow("Travel Class", viewModel.flight.travelClass)
                    infoRow("Legroom", viewModel.flight.legroom)
                    infoRow("Overnight Flight", viewModel.flight.isOvernight ? "Yes" : "No")
                    infoRow("Often Delayed", viewModel.flight.oftenDelayed ? "Yes" : "No")
                }
                
                if let emissions = viewModel.flight.carbonEmissions {
                    Group {
                        Text("Carbon Emissions:")
                            .font(.headline)
                        infoRow("This Flight", "\(emissions.this_flight)g")
                        infoRow("Typical for Route", "\(emissions.typical_for_this_route)g")
                        infoRow("Difference", "\(emissions.difference_percent)%")
                    }
                } else {
                    Text("Carbon emissions data not available.")
                        .foregroundColor(.gray)
                }
                
                Divider()
                
                // User Input
                TextField("Ask a question about this flight", text: $userQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.vertical)
                
                Button(action: {
                    submitQuery()
                }) {
                    Text("Submit")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                // Loading Indicator
                if isLoading {
                    ProgressView("Processing...")
                        .padding()
                }
                
                // Error Message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                // Dynamic Content
                viewModel.dynamicContent
            }
            .padding()
        }
        .navigationTitle("Flight Details")
    }
    
    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            Text(value)
        }
    }
    
    func submitQuery() {
        isLoading = true
        errorMessage = nil
        viewModel.processUserQuery(userQuery) { success, error in
            isLoading = false
            if let error = error {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }
}
