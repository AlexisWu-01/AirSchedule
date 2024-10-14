//
//  DynamicUIRenderer.swift
//  AirSchedule
//
//  Created by Xinyi WU on 10/14/24.
//

import SwiftUI

struct DynamicUIRenderer: View {
    let components: [String]
    let context: [String: Any]

    var body: some View {
        VStack {
            ForEach(components, id: \.self) { component in
                switch component {
                case "meeting_availability_result":
                    if let canMakeMeeting = context["can_make_meeting"] as? Bool {
                        MeetingAvailabilityView(canMakeIt: canMakeMeeting)
                    } else {
                        Text("Unable to determine meeting availability.")
                            .foregroundColor(.red)
                    }
                case "legroom_status_display":
                    LegroomStatusView()
                // Add more cases as needed
                default:
                    Text("Unknown component: \(component)")
                        .foregroundColor(.red)
                }
            }
        }
    }
}

// Example UI Components


struct LegroomStatusView: View {
    // Populate with actual data
    var body: some View {
        Text("Legroom Status: Extra Legroom Available")
            .font(.subheadline)
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
    }
}

struct MeetingAvailabilityView: View {
    let canMakeIt: Bool

    var body: some View {
        VStack {
            Image(systemName: canMakeIt ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(canMakeIt ? .green : .red)
                .font(.largeTitle)
            Text(canMakeIt ? "You can make it to your meeting!" : "You might not make it to your meeting.")
                .font(.headline)
                .foregroundColor(canMakeIt ? .green : .red)
        }
        .padding()
        .background(Color(canMakeIt ? .green : .red).opacity(0.1))
        .cornerRadius(10)
    }
}
