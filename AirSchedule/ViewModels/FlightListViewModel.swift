//
//  FlightListViewModel.swift
//  AirSchedule
//
//  Created by Xinyi WU on 10/13/24.
//

import Foundation

enum FlightSortOption {
    case departureTime
    case arrivalTime
    case price
}

class FlightListViewModel: ObservableObject {
    @Published var flights: [Flight] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var departureAirport: String = "SAN"
    @Published var arrivalAirport: String = "SFO"
    @Published var flightDate: Date = Date()
    @Published var sortOption: FlightSortOption = .departureTime
    @Published var filteredFlights: [Flight] = []

    var selectedDepartureAirport: String {
        departureAirport
    }
    
    var selectedArrivalAirport: String {
        arrivalAirport
    }

    init() {
        fetchFlights()
    }

    func fetchFlights() {
        isLoading = true
        errorMessage = nil

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        print("Fetching flights for date: \(dateFormatter.string(from: flightDate))")

        FlightService.shared.fetchFlights(from: selectedDepartureAirport, to: selectedArrivalAirport, on: flightDate) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let flights):
                    self?.flights = flights
                    self?.filterFlights()
                    print("Number of flights fetched: \(flights.count)")
                    if flights.isEmpty {
                        self?.errorMessage = "No flights found for the selected route and date."
                    }
                case .failure(let error):
                    self?.errorMessage = "Error fetching flights: \(error.localizedDescription)"
                    print("Error fetching flights: \(error)")
                }
            }
        }
    }

    func sortFlights() {
        switch sortOption {
        case .departureTime:
            filteredFlights.sort { $0.departureTime < $1.departureTime }
        case .arrivalTime:
            filteredFlights.sort { $0.arrivalTime < $1.arrivalTime }
        case .price:
            filteredFlights.sort { $0.price < $1.price }
        }
    }

    func changeSortOption(_ option: FlightSortOption) {
        sortOption = option
        sortFlights()
    }

    func filterFlights() {
        filteredFlights = flights
        sortFlights()
    }
}
