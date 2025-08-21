//
//  AutomaticAttendanceManager.swift
//  Yooh
//
//  Created by Derrick ng'ang'a on 07/08/2025.
//

import Foundation
import CoreLocation
import SwiftData

class AutomaticAttendanceManager: ObservableObject {
    private var attendanceManager: AttendanceManager
    private var locationManager: LocationManager
    private var modelContext: ModelContext
    private var timer: Timer?

    init(attendanceManager: AttendanceManager,
         locationManager: LocationManager,
         modelContext: ModelContext) {
        self.attendanceManager = attendanceManager
        self.locationManager = locationManager
        self.modelContext = modelContext
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkAttendance()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func checkAttendance() {
        let now = Date()

        // Get current day as string to avoid enum comparison issues
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: now)
        let currentDayString: String
        switch weekday {
        case 1: currentDayString = "sunday"
        case 2: currentDayString = "monday"
        case 3: currentDayString = "tuesday"
        case 4: currentDayString = "wednesday"
        case 5: currentDayString = "thursday"
        case 6: currentDayString = "friday"
        case 7: currentDayString = "saturday"
        default: currentDayString = "monday"
        }

        // Fetch all classes and filter manually
        let descriptor = FetchDescriptor<SchoolClass>(
            predicate: #Predicate { schoolClass in
                schoolClass.startDate <= now &&
                schoolClass.endDate >= now
            }
        )

        do {
            let timeFilteredClasses = try modelContext.fetch(descriptor)
            // Filter by day of week manually using string comparison
            let activeClasses = timeFilteredClasses.filter { $0.dayOfWeek.rawValue == currentDayString }

            if let activeClass = activeClasses.first,
               locationManager.isWithinSchool {

                _ = attendanceManager.signAttendance(
                    for: activeClass,
                    location: locationManager.currentLocation
                )
            }
        } catch {
            print("SwiftData fetch failed: \(error)")
        }
    }
}

extension DayOfWeek {
    init(date: Date) {
        let weekday = Calendar.current.component(.weekday, from: date)
        switch weekday {
        case 1: self = .sunday
        case 2: self = .monday
        case 3: self = .tuesday
        case 4: self = .wednesday
        case 5: self = .thursday
        case 6: self = .friday
        case 7: self = .saturday
        default: self = .monday
        }
    }
}
