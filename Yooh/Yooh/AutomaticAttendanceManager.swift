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
        let currentDay = DayOfWeek(date: now)

        let descriptor = FetchDescriptor<SchoolClass>(
            predicate: #Predicate {
                $0.dayOfWeek == currentDay &&
                $0.startDate <= now &&
                $0.endDate >= now
            }
        )

        do {
            let activeClasses = try modelContext.fetch(descriptor)
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
