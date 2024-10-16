//
//  Meeting.swift
//  AirSchedule
//
//  Created by Xinyi WU on 10/15/24.
//
//
import SwiftUI

struct MeetingAvailabilityView: View {
    let title: String
    let time: Date
    let location: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            HStack {
                Image(systemName: "clock")
                Text(formattedDate(time))
            }
            .font(.subheadline)
            
            HStack {
                Image(systemName: "mappin.and.ellipse")
                Text(location)
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func formattedDate(_ date: Date) -> String {
        DateFormatter.shortDateTime.string(from: date)
    }
}