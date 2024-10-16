//
//  Meeting.swift
//  AirSchedule
//
//  Created by Xinyi WU on 10/15/24.
//
//
import SwiftUI

struct MeetingAvailabilityView: View {
    let meetingData: [String: AnyCodable]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(meetingData["title"]?.value as? String ?? "Unknown Event")
                .font(.headline)
            Text("StartTime: \(formattedTime(meetingData["startTime"]?.value as? String))")
            Text("Location: \(meetingData["location"]?.value as? String ?? "Unknown Location")")
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }

    private func formattedTime(_ isoString: String?) -> String {
        guard let isoString = isoString,
              let date = ISO8601DateFormatter().date(from: isoString) else {
            return "Unknown Time"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
