//
//  SearchBar.swift
//  AirSchedule
//
//  Created by Xinyi WU on 10/13/24.
//

import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var onSearchButtonClicked: () -> Void

    var body: some View {
        HStack {
            TextField("Search flights", text: $text)
                .padding(7)
                .padding(.horizontal, 25)
                .background(Color.white)
                .cornerRadius(8)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.airBlue)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)
                        
                        if !text.isEmpty {
                            Button(action: {
                                self.text = ""
                            }) {
                                Image(systemName: "multiply.circle.fill")
                                    .foregroundColor(.airDarkGray)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                )
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
            
            Button("Search") {
                onSearchButtonClicked()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.airBlue)
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        }
    }
}
