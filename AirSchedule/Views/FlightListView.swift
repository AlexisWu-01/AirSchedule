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
            VStack {
                Form {
                    Section(header: Text("Search Flights")) {
                        TextField("Departure Airport", text: $viewModel.departureAirport)
                        TextField("Arrival Airport", text: $viewModel.arrivalAirport)
                        DatePicker("Flight Date", selection: $viewModel.flightDate, displayedComponents: .date)
                    }
                    
                    Button(action: {
                        viewModel.fetchFlights()
                    }) {
                        Text("Search Flights")
                    }
                }

                Picker("Sort by", selection: $viewModel.sortOption) {
                    Text("Departure Time").tag(FlightSortOption.departureTime)
                    Text("Arrival Time").tag(FlightSortOption.arrivalTime)
                    Text("Price").tag(FlightSortOption.price)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .onChange(of: viewModel.sortOption) { _ in
                    viewModel.sortFlights()
                }

                if viewModel.filteredFlights.isEmpty && !viewModel.isLoading {
                    Text("No flights found")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(viewModel.filteredFlights) { flight in
                        NavigationLink(destination: FlightDetailView(viewModel: FlightDetailViewModel(flight: flight))) {
                            FlightRowView(flight: flight)
                        }
                    }
                    .listStyle(PlainListStyle())
                }

                if viewModel.isLoading {
                    ProgressView("Loading flights...")
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationTitle("Flights")
        }
    }
}

struct FlightRowView: View {
    let flight: Flight

    var body: some View {
        VStack(alignment: .leading) {
            Text("\(flight.airlineCode) Flight \(flight.flightNumber)")
                .font(.headline)
            Text("\(flight.departureAirport) → \(flight.arrivalAirport)")
            Text("Departure: \(formattedDate(flight.departureTime))")
            Text("Arrival: \(formattedDate(flight.arrivalTime))")
            Text("Price: $\(String(format: "%.2f", flight.price))")
        }
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
