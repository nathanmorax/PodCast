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

    /// When an episode came out, short: "Today", "Yesterday", the weekday
    /// within the last week ("Tue"), otherwise the date ("Oct 14").
    func shortDayText(now: Date = .now, calendar: Calendar = .current) -> String {
        if calendar.isDate(self, inSameDayAs: now) {
            return String(localized: "Today")
        }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(self, inSameDayAs: yesterday) {
            return String(localized: "Yesterday")
        }
        if let weekAgo = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)),
           self >= weekAgo, self <= now {
            return formatted(.dateTime.weekday(.abbreviated))
        }
        return formatted(.dateTime.day().month(.abbreviated))
    }
}
