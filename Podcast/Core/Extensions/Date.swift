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
            formatter.setLocalizedDateFormatFromTemplate("MMMd")  // "14 oct" in Spanish
        } else {
            formatter.setLocalizedDateFormatFromTemplate("MMMdyyyy")
        }
        
        return formatter.string(from: self)
    }
}

