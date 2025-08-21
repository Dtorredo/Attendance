import Foundation
import Combine
import SwiftData

class CalendarManager: NSObject, ObservableObject {
    @Published var scheduledDates: [Date] = []
    @Published var classesForDate: [Date: [SchoolClass]] = [:]
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
        var classesForDateDict: [Date: [SchoolClass]] = [:]

        for classTemplate in allClassTemplates {
            let occurrences = getOccurrences(for: classTemplate, in: monthInterval, calendar: calendar)
            allOccurrences.append(contentsOf: occurrences)

            // Map each occurrence date to the class
            for occurrence in occurrences {
                let dayKey = calendar.startOfDay(for: occurrence)
                if classesForDateDict[dayKey] == nil {
                    classesForDateDict[dayKey] = []
                }
                classesForDateDict[dayKey]?.append(classTemplate)
            }
        }

        self.scheduledDates = allOccurrences
        self.classesForDate = classesForDateDict
    }
    
    private func getOccurrences(for schoolClass: SchoolClass, in interval: DateInterval, calendar: Calendar) -> [Date] {
        var occurrences: [Date] = []
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: schoolClass.startDate)

        // For recurring classes, check if this class has a recurring pattern
        // If it's a single class, just return the start date if it's in the interval
        if !schoolClass.isRecurring {
            if interval.contains(schoolClass.startDate) {
                occurrences.append(schoolClass.startDate)
            }
            return occurrences
        }

        // For recurring classes, generate occurrences based on day of week
        var currentDate = max(interval.start, schoolClass.startDate)
        let classEndDate = schoolClass.endDate
        let intervalEnd = min(interval.end, classEndDate)

        while currentDate <= intervalEnd {
            let weekday = DayOfWeek(date: currentDate).rawValue
            if weekday == schoolClass.dayOfWeek.rawValue {
                if let occurrence = calendar.date(bySettingHour: timeComponents.hour ?? 0, minute: timeComponents.minute ?? 0, second: timeComponents.second ?? 0, of: currentDate) {
                    // Add all occurrences within the class period, not just future ones
                    if occurrence >= schoolClass.startDate && occurrence <= classEndDate {
                        occurrences.append(occurrence)
                    }
                }
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        return occurrences
    }

    // Get classes for a specific date
    func getClassesForDate(_ date: Date) -> [SchoolClass] {
        let calendar = Calendar.current
        let dayKey = calendar.startOfDay(for: date)
        return classesForDate[dayKey] ?? []
    }
}