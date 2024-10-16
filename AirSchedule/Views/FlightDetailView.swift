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
                flightHeader

                // Flight Details
                flightDetails

                // Dynamic UI Components
                DynamicUIRenderer(uiComponents: viewModel.uiComponents)

                // User Query Input
                userQueryInput
            }
            .padding()
        }
        .navigationBarTitle("Flight Details", displayMode: .inline)
    }

    private var flightHeader: some View {
        HStack {
            AsyncImage(url: URL(string: viewModel.flight.airlineLogo)) { image in
                image.resizable().aspectRatio(contentMode: .fit)
            } placeholder: {
                ProgressView()
            }
            .frame(width: 50, height: 50)

            VStack(alignment: .leading) {
                Text(viewModel.flight.airline)
                    .font(.headline)
                Text(viewModel.flight.flightNumber)
                    .font(.subheadline)
            }

            Spacer()

            Text("$\(String(format: "%.2f", viewModel.flight.price))")
                .font(.title2)
                .fontWeight(.bold)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }

    private var flightDetails: some View {
        VStack(alignment: .leading, spacing: 15) {
            flightTimeRow
            flightDurationRow
            flightClassRow
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }

    private var flightTimeRow: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(viewModel.flight.departureAirport)
                    .font(.headline)
                Text(formatDate(viewModel.flight.departureTime))
                    .font(.subheadline)
            }

            Spacer()

            Image(systemName: "airplane")
                .foregroundColor(.blue)

            Spacer()

            VStack(alignment: .trailing) {
                Text(viewModel.flight.arrivalAirport)
                    .font(.headline)
                Text(formatDate(viewModel.flight.arrivalTime))
                    .font(.subheadline)
            }
        }
    }

    private var flightDurationRow: some View {
        HStack {
            Image(systemName: "clock")
            Text("Duration: \(formatDuration(TimeInterval(viewModel.flight.duration * 60)))")
        }
    }

    private var flightClassRow: some View {
        HStack {
            Image(systemName: "seat.fill")
            Text("Class: \(viewModel.flight.travelClass)")
        }
    }

    private var userQueryInput: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Ask a question about your flight:")
                .font(.headline)
            TextField("Enter your query here", text: $userQuery, onCommit: submitQuery)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(isLoading)

            if isLoading {
                ProgressView()
            }

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
        }
    }

    private func submitQuery() {
        guard !userQuery.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isLoading = true
        errorMessage = nil
        viewModel.processUserQuery(userQuery) { success, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if !success {
                    self.errorMessage = error?.localizedDescription ?? "An error occurred"
                }
                self.userQuery = ""
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm, MMM d"
        return formatter.string(from: date)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600))/60)
        return "\(hours)h \(minutes)m"
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(8)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}
