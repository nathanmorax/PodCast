//
//  Date.swift
//  Podcast
//
//  Created by Jonathan Mora on 05/06/26.
//

import Foundation

extension Date {
    func formattedDate() -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let yearOfDate = calendar.component(.year, from: self)
        
        if yearOfDate == currentYear {
            formatter.dateFormat = "MMM d"
        } else {
            formatter.dateFormat = "MMM d, yyyy"
        }
        
        return formatter.string(from: self)
    }
}

