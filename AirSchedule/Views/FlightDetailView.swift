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
                flightHeader
                flightDetails
                DynamicUIRenderer(uiComponents: viewModel.uiComponents)
                userQueryInput
            }
            .padding()
        }
        .navigationBarTitle("Flight Details", displayMode: .inline)
        .background(Color.airLightBlue)
    }

    private var flightHeader: some View {
        VStack(spacing: 16) {
            HStack {
                AsyncImage(url: URL(string: viewModel.flight.airlineLogo)) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 60, height: 60)
                .cornerRadius(30)

                VStack(alignment: .leading) {
                    Text(viewModel.flight.airline)
                        .font(.headline)
                    Text(viewModel.flight.flightNumber)
                        .font(.subheadline)
                        .foregroundColor(.airDarkGray)
                }

                Spacer()

                Text("$\(String(format: "%.2f", viewModel.flight.price))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.airBlue)
            }

            Divider()

            HStack {
                VStack(alignment: .leading) {
                    Text(viewModel.flight.departureAirport)
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text(formatDate(viewModel.flight.departureTime))
                        .font(.subheadline)
                        .foregroundColor(.airDarkGray)
                }

                Spacer()

                Image(systemName: "airplane")
                    .foregroundColor(.airBlue)
                    .font(.system(size: 24))

                Spacer()

                VStack(alignment: .trailing) {
                    Text(viewModel.flight.arrivalAirport)
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text(formatDate(viewModel.flight.arrivalTime))
                        .font(.subheadline)
                        .foregroundColor(.airDarkGray)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    private var flightDetails: some View {
        VStack(alignment: .leading, spacing: 16) {
            detailRow(icon: "clock", title: "Duration", value: formatDuration(TimeInterval(viewModel.flight.duration * 60)))
            detailRow(icon: "seat.fill", title: "Class", value: viewModel.flight.travelClass)
            detailRow(icon: "ruler", title: "Legroom", value: "\(viewModel.flight.legroom) inches")
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.airBlue)
                .frame(width: 30)
            Text(title)
                .foregroundColor(.airDarkGray)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }

    private var userQueryInput: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Ask about your flight:")
                .font(.headline)
            HStack {
                TextField("Enter your query here", text: $userQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(isLoading)
                Button(action: submitQuery) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.airBlue)
                        .cornerRadius(8)
                }
                .disabled(isLoading || userQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if isLoading {
                ProgressView()
            }

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
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
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }
}
