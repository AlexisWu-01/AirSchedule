//
//  MeetingAvailabilityView.swift
//  AirSchedule
//
//  Created by Xinyi WU on 10/14/24.
//

import SwiftUI

struct MeetingAvailabilityView: View {
    let canMakeIt: Bool
    let timeDifference: TimeInterval
    let meeting: Meeting

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Meeting Details")
                .font(.headline)
            Text("Title: \(meeting.title)")
            Text("Start Time: \(formattedDate(meeting.startTime))")
            Text("Location: \(meeting.location)")

            if canMakeIt {
                Text("You can make it to your meeting!")
                    .foregroundColor(.green)
            } else {
                Text("You will not make it to your meeting on time.")
                    .foregroundColor(.red)
            }

            Text("Time difference: \(formatTimeDifference(timeDifference))")
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    func formatTimeDifference(_ interval: TimeInterval) -> String {
        let hours = Int(abs(interval)) / 3600
        let minutes = (Int(abs(interval)) % 3600) / 60
        let sign = interval >= 0 ? "" : "-"
        return "\(sign)\(hours)h \(minutes)m"
    }
}
