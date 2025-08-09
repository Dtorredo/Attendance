import Foundation
import Combine
import SwiftData

// A new struct to hold a class and its next calculated occurrence.
struct UpcomingClassViewModel: Identifiable, Hashable {
    let id: String
    let title: String
    let location: String?
    let nextOccurrence: Date
}

class CalendarManager: NSObject, ObservableObject {
    @Published var upcomingClasses: [UpcomingClassViewModel] = []
    private var modelContext: ModelContext? = nil

    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        refreshData()
    }
    
    func refreshData() {
        guard let modelContext = modelContext else { return }
        
        // 1. Fetch all class templates from the database.
        let descriptor = FetchDescriptor<SchoolClass>()
        guard let allClassTemplates = try? modelContext.fetch(descriptor) else {
            return
        }
        
        let now = Date()
        let calendar = Calendar.current
        var calculatedUpcomingClasses: [UpcomingClassViewModel] = []
        
        // 2. For each template, calculate its next real-world occurrence.
        for classTemplate in allClassTemplates {
            guard let nextDate = getNextOccurrence(for: classTemplate, after: now, calendar: calendar) else { continue }
            
            let viewModel = UpcomingClassViewModel(
                id: classTemplate.id,
                title: classTemplate.title,
                location: classTemplate.location,
                nextOccurrence: nextDate
            )
            calculatedUpcomingClasses.append(viewModel)
        }
        
        // 3. Sort the results by the calculated next occurrence and update the published property.
        self.upcomingClasses = calculatedUpcomingClasses.sorted { $0.nextOccurrence < $1.nextOccurrence }
    }
    
    private func getNextOccurrence(for schoolClass: SchoolClass, after date: Date, calendar: Calendar) -> Date? {
        // Get the time components from the original start date
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: schoolClass.startDate)
        
        // Find the next date that matches the class's weekday
        var searchDate = calendar.startOfDay(for: date)
        while true {
            let searchWeekday = DayOfWeek(date: searchDate).rawValue
            if searchWeekday == schoolClass.dayOfWeek.rawValue {
                // Use 'let' as the user correctly pointed out.
                if let nextOccurrence = calendar.date(bySettingHour: timeComponents.hour ?? 0, minute: timeComponents.minute ?? 0, second: timeComponents.second ?? 0, of: searchDate) {
                    // If the calculated time is in the past for today, check from tomorrow instead.
                    if nextOccurrence < date {
                        searchDate = calendar.date(byAdding: .day, value: 1, to: searchDate)!
                        continue
                    }
                    return nextOccurrence
                }
            }
            searchDate = calendar.date(byAdding: .day, value: 1, to: searchDate)!
            
            // Safety break after a year of searching
            if searchDate > calendar.date(byAdding: .year, value: 1, to: date)! { return nil }
        }
    }
}