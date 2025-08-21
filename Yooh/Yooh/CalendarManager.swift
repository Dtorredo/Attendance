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
        print("🔄 CalendarManager.refreshData called for date: \(date)")
        guard let modelContext = modelContext else { 
            print("❌ ModelContext is nil")
            return 
        }

        let descriptor = FetchDescriptor<SchoolClass>()
        guard let allClassTemplates = try? modelContext.fetch(descriptor) else {
            print("❌ Failed to fetch classes from ModelContext")
            return
        }

        print("📚 Found \(allClassTemplates.count) classes in database")

        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else { 
            print("❌ Failed to create month interval")
            return 
        }

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

        print("📅 Generated \(allOccurrences.count) total occurrences")
        print("📅 Classes mapped to \(classesForDateDict.count) different dates")

        self.scheduledDates = allOccurrences
        self.classesForDate = classesForDateDict
    }
    
    private func getOccurrences(for schoolClass: SchoolClass, in interval: DateInterval, calendar: Calendar) -> [Date] {
        var occurrences: [Date] = []
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: schoolClass.startDate)

        print("🔍 Processing class: \(schoolClass.title)")
        print("   - Is recurring: \(schoolClass.isRecurring)")
        print("   - Start date: \(schoolClass.startDate)")
        print("   - End date: \(schoolClass.endDate)")
        print("   - Day of week: \(schoolClass.dayOfWeek.rawValue)")

        // For non-recurring classes, just return the start date if it's in the interval
        if !schoolClass.isRecurring {
            if interval.contains(schoolClass.startDate) {
                occurrences.append(schoolClass.startDate)
                print("   - Single class occurrence added")
            }
            return occurrences
        }

        // For recurring classes, generate weekly occurrences
        var currentDate = max(interval.start, schoolClass.startDate)
        let classEndDate = schoolClass.endDate
        let intervalEnd = min(interval.end, classEndDate)

        print("   - Interval: \(interval.start) to \(intervalEnd)")

        // Find the first occurrence of this class in the interval
        while currentDate <= intervalEnd {
            let weekday = calendar.component(.weekday, from: currentDate)
            let targetWeekday = getWeekdayNumber(for: schoolClass.dayOfWeek)
            
            if weekday == targetWeekday {
                if let occurrence = calendar.date(bySettingHour: timeComponents.hour ?? 0, minute: timeComponents.minute ?? 0, second: timeComponents.second ?? 0, of: currentDate) {
                    // Only add if it's within the class period
                    if occurrence >= schoolClass.startDate && occurrence <= classEndDate {
                        occurrences.append(occurrence)
                        print("   - Weekly occurrence added: \(occurrence)")
                    }
                }
                // Move to next week (7 days later)
                currentDate = calendar.date(byAdding: .day, value: 7, to: currentDate) ?? currentDate
            } else {
                // Move to next day
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
        }
        
        print("   - Total occurrences: \(occurrences.count)")
        return occurrences
    }
    
    // Helper function to convert DayOfWeek enum to Calendar weekday number
    private func getWeekdayNumber(for dayOfWeek: DayOfWeek) -> Int {
        switch dayOfWeek {
        case .sunday: return 1
        case .monday: return 2
        case .tuesday: return 3
        case .wednesday: return 4
        case .thursday: return 5
        case .friday: return 6
        case .saturday: return 7
        }
    }

    // Get classes for a specific date
    func getClassesForDate(_ date: Date) -> [SchoolClass] {
        let calendar = Calendar.current
        let dayKey = calendar.startOfDay(for: date)
        return classesForDate[dayKey] ?? []
    }
}