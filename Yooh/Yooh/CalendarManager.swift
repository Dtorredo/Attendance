import Foundation
import Combine
import SwiftData

class CalendarManager: NSObject, ObservableObject {
    @Published var scheduledDates: [Date] = []
    private var modelContext: ModelContext? = nil

    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        refreshData()
    }
    
    func refreshData(for date: Date = Date()) {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<SchoolClass>()
        guard let allClassTemplates = try? modelContext.fetch(descriptor) else {
            return
        }
        
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else { return }
        
        var allOccurrences: [Date] = []
        for classTemplate in allClassTemplates {
            let occurrences = getOccurrences(for: classTemplate, in: monthInterval, calendar: calendar)
            allOccurrences.append(contentsOf: occurrences)
        }
        
        self.scheduledDates = allOccurrences
    }
    
    private func getOccurrences(for schoolClass: SchoolClass, in interval: DateInterval, calendar: Calendar) -> [Date] {
        var occurrences: [Date] = []
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: schoolClass.startDate)
        
        var currentDate = interval.start
        while currentDate <= interval.end {
            let weekday = DayOfWeek(date: currentDate).rawValue
            if weekday == schoolClass.dayOfWeek.rawValue {
                if let occurrence = calendar.date(bySettingHour: timeComponents.hour ?? 0, minute: timeComponents.minute ?? 0, second: timeComponents.second ?? 0, of: currentDate) {
                    if occurrence >= Date() { // Only add future dates
                        occurrences.append(occurrence)
                    }
                }
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        return occurrences
    }
}