//
//  AirScheduleApp.swift
//  AirSchedule
//
//  Created by Xinyi WU on 10/13/24.
//

// AirScheduleApp.swift
import SwiftUI

@main
struct AirScheduleApp: App {
    var body: some Scene {
        WindowGroup {
            FlightListView(viewModel: FlightListViewModel())
        }
    }
}
