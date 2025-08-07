//
//  AttendanceManager.swift
//  Yooh
//
//  Created by Derrick ng'ang'a on 06/08/2025.
//

import Foundation
import Combine
import CoreLocation
import SwiftData

class AttendanceManager: ObservableObject {
    @Published var attendanceRecords: [AttendanceRecord] = []
    private var modelContext: ModelContext? = nil

    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchAttendanceRecords()
    }

    func signAttendance(for schoolClass: SchoolClass, location: CLLocation?) -> Bool {
        guard let modelContext = modelContext else { return false }

        guard !hasSigned(for: schoolClass) else {
            return false
        }

        let currentLocation = location ?? CLLocation(latitude: 0, longitude: 0)

        let newRecord = AttendanceRecord(
            timestamp: Date(),
            status: .onTime,
            latitude: currentLocation.coordinate.latitude,
            longitude: currentLocation.coordinate.longitude
        )
        newRecord.schoolClass = schoolClass

        modelContext.insert(newRecord)
        fetchAttendanceRecords()
        return true
    }

    func hasSigned(for schoolClass: SchoolClass) -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return attendanceRecords.contains { record in
            record.schoolClass?.id == schoolClass.id && Calendar.current.isDate(record.timestamp, inSameDayAs: today)
        }
    }

    func getTotalAttendanceDays() -> Int {
        return attendanceRecords.count
    }

    func getMonthlyAttendance() -> Int {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        let currentYear = calendar.component(.year, from: Date())

        return attendanceRecords.filter { record in
            let recordMonth = calendar.component(.month, from: record.timestamp)
            let recordYear = calendar.component(.year, from: record.timestamp)
            return recordMonth == currentMonth && recordYear == currentYear
        }.count
    }

    func getCurrentStreak() -> Int {
        guard !attendanceRecords.isEmpty else { return 0 }

        let calendar = Calendar.current
        let sortedRecords = attendanceRecords.sorted { $0.timestamp > $1.timestamp }

        var streak = 0
        var currentDate = Date()

        for record in sortedRecords {
            if calendar.isDate(record.timestamp, inSameDayAs: currentDate) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else if calendar.isDate(record.timestamp, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }

        return streak
    }

    func getAttendanceForDate(_ date: Date) -> AttendanceRecord? {
        return attendanceRecords.first { record in
            Calendar.current.isDate(record.timestamp, inSameDayAs: date)
        }
    }

    func getTodaysRecord() -> AttendanceRecord? {
        return getAttendanceForDate(Date())
    }

    func getAttendanceForMonth(_ date: Date) -> [AttendanceRecord] {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)

        return attendanceRecords.filter { record in
            let recordMonth = calendar.component(.month, from: record.timestamp)
            let recordYear = calendar.component(.year, from: record.timestamp)
            return recordMonth == month && recordYear == year
        }.sorted { $0.timestamp > $1.timestamp }
    }

    private func fetchAttendanceRecords() {
        guard let modelContext = modelContext else { return }
        let descriptor = FetchDescriptor<AttendanceRecord>(sortBy: [SortDescriptor(\AttendanceRecord.timestamp, order: .reverse)])
        do {
            attendanceRecords = try modelContext.fetch(descriptor)
        } catch {
            print("Fetch failed")
        }
    }
}