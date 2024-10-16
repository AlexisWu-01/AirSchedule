//
//  FlightListView.swift
//  AirSchedule
//
//  Created by Xinyi WU on 10/13/24.
//

import SwiftUI

struct FlightListView: View {
    @ObservedObject var viewModel: FlightListViewModel

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                flightSearchForm
                
                Picker("Sort by", selection: $viewModel.sortOption) {
                    Text("Departure").tag(FlightSortOption.departureTime)
                    Text("Arrival").tag(FlightSortOption.arrivalTime)
                    Text("Price").tag(FlightSortOption.price)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .background(Color.airLightBlue)
                .onChange(of: viewModel.sortOption) { _ in
                    viewModel.sortFlights()
                }

                if viewModel.isLoading {
                    ProgressView("Loading flights...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.airLightBlue)
                } else if viewModel.filteredFlights.isEmpty {
                    emptyStateView
                } else {
                    flightList
                }
            }
            .background(Color.airLightBlue)
            .navigationTitle("Flights")
        }
        .accentColor(.airBlue)
    }

    private var flightSearchForm: some View {
        VStack(spacing: 16) {
            HStack {
                TextField("From", text: $viewModel.departureAirport)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("To", text: $viewModel.arrivalAirport)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                DatePicker("", selection: $viewModel.flightDate, displayedComponents: .date)
                    .labelsHidden()
            }
            .padding(.horizontal)
            
            Button(action: {
                viewModel.fetchFlights()
            }) {
                Text("Search Flights")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color.white)
    }

    private var emptyStateView: some View {
        VStack {
            Image(systemName: "airplane")
                .font(.system(size: 60))
                .foregroundColor(.airBlue)
            Text("No flights found")
                .font(.headline)
            Text("Try adjusting your search criteria")
                .font(.subheadline)
                .foregroundColor(.airDarkGray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.airLightBlue)
    }

    private var flightList: some View {
        List {
            ForEach(viewModel.filteredFlights) { flight in
                NavigationLink(destination: FlightDetailView(viewModel: FlightDetailViewModel(flight: flight))) {
                    FlightRowView(flight: flight)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct FlightRowView: View {
    let flight: Flight
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(flight.airlineCode) \(flight.flightNumber)")
                    .font(.headline)
                    .foregroundColor(.airBlue)
                Text("\(formattedTime(flight.departureTime)) → \(formattedTime(flight.arrivalTime))")
                    .font(.subheadline)
                    .foregroundColor(.airDarkGray)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(String(format: "%.2f", flight.price))")
                    .font(.headline)
                    .foregroundColor(.airBlue)
                Text(formattedDuration(flight.duration))
                    .font(.subheadline)
                    .foregroundColor(.airDarkGray)
            }
        }
        .padding(.vertical, 8)
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func formattedDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        return "\(hours)h \(mins)m"
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.airBlue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}
