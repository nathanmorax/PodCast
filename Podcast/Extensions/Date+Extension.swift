


import Foundation

extension Date {
    func formattedDate() -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let yearOfDate = calendar.component(.year, from: self)
        
        if yearOfDate == currentYear {
            // Solo mes y día
            formatter.dateFormat = "MMM d"
        } else {
            // Mes, día y año
            formatter.dateFormat = "MMM d, yyyy"
        }
        
        return formatter.string(from: self)
    }
}
