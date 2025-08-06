//
//  AttendanceManager.swift
//  Yooh
//
//  Created by Derrick ng'ang'a on 06/08/2025.
//

import Foundation
import Combine
import CoreLocation

struct AttendanceRecord: Codable, Identifiable {
    let id: UUID
    let date: Date
    let location: LocationData
    
    struct LocationData: Codable {
        let latitude: Double
        let longitude: Double
    }
    
    // Custom initializer
    init(date: Date, location: LocationData) {
        self.id = UUID()
        self.date = date
        self.location = location
    }
    
    // Custom initializer for decoding
    init(id: UUID, date: Date, location: LocationData) {
        self.id = id
        self.date = date
        self.location = location
    }
}

class AttendanceManager: ObservableObject {
    @Published var attendanceRecords: [AttendanceRecord] = []
    
    private let userDefaults = UserDefaults.standard
    private let attendanceKey = "AttendanceRecords"
    
    init() {
        loadAttendanceRecords()
    }
    
    func signAttendance(location: CLLocation?) -> Bool {
        guard !hasSignedToday() else {
            return false
        }
        
        let currentLocation = location ?? CLLocation(latitude: 0, longitude: 0)
        
        let newRecord = AttendanceRecord(
            date: Date(),
            location: AttendanceRecord.LocationData(
                latitude: currentLocation.coordinate.latitude,
                longitude: currentLocation.coordinate.longitude
            )
        )
        
        attendanceRecords.insert(newRecord, at: 0)
        saveAttendanceRecords()
        return true
    }
    
    func hasSignedToday() -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return attendanceRecords.contains { record in
            Calendar.current.isDate(record.date, inSameDayAs: today)
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
            let recordMonth = calendar.component(.month, from: record.date)
            let recordYear = calendar.component(.year, from: record.date)
            return recordMonth == currentMonth && recordYear == currentYear
        }.count
    }
    
    func getCurrentStreak() -> Int {
        guard !attendanceRecords.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let sortedRecords = attendanceRecords.sorted { $0.date > $1.date }
        
        var streak = 0
        var currentDate = Date()
        
        for record in sortedRecords {
            if calendar.isDate(record.date, inSameDayAs: currentDate) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else if calendar.isDate(record.date, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    // ✅ YES! I'm adding the EXACT method you asked for
    func getAttendanceForDate(_ date: Date) -> AttendanceRecord? {
        return attendanceRecords.first { record in
            Calendar.current.isDate(record.date, inSameDayAs: date)
        }
    }
    
    // ✅ BONUS: Additional helpful methods
    func getTodaysRecord() -> AttendanceRecord? {
        return getAttendanceForDate(Date())
    }
    
    func getAttendanceForMonth(_ date: Date) -> [AttendanceRecord] {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        
        return attendanceRecords.filter { record in
            let recordMonth = calendar.component(.month, from: record.date)
            let recordYear = calendar.component(.year, from: record.date)
            return recordMonth == month && recordYear == year
        }.sorted { $0.date > $1.date }
    }
    
    private func loadAttendanceRecords() {
        guard let data = userDefaults.data(forKey: attendanceKey),
              let records = try? JSONDecoder().decode([AttendanceRecord].self, from: data) else {
            return
        }
        attendanceRecords = records
    }
    
    private func saveAttendanceRecords() {
        guard let data = try? JSONEncoder().encode(attendanceRecords) else {
            return
        }
        userDefaults.set(data, forKey: attendanceKey)
    }
}
