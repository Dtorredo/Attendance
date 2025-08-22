//
//  AttendanceManager.swift
//  Yooh
//
//  Created by Derrick ng'ang'a on 07/08/2025.
//

import Foundation
import Combine
import CoreLocation
import SwiftData
import Network

class AttendanceManager: ObservableObject {
    @Published var attendanceRecords: [AttendanceRecord] = []

    private var modelContext: ModelContext?
    private var authToken: String?
    private var currentUserId: String?
    private var onFetchFinished: () -> Void = {}
    
    // Public property to check if manager is ready
    var isReady: Bool {
        return modelContext != nil
    }

    // MARK: - Setup
    func setup(
        modelContext: ModelContext,
        authToken: String?,
        currentUserId: String?,
        onFetchFinished: @escaping () -> Void = {}
    ) {
        self.modelContext = modelContext
        self.authToken = authToken
        self.currentUserId = currentUserId
        self.onFetchFinished = onFetchFinished
        fetchAttendanceRecords()
    }

    // MARK: - Public helpers
    func signAttendance(for schoolClass: SchoolClass,
                        location: CLLocation?) -> Bool {
        guard let modelContext else { return false }
        guard !hasSigned(for: schoolClass) else { return false }

        let loc = location ?? CLLocation(latitude: 0, longitude: 0)
        let record = AttendanceRecord(
            userId: currentUserId ?? "",
            timestamp: Date(),
            status: .onTime,
            latitude: loc.coordinate.latitude,
            longitude: loc.coordinate.longitude
        )
        record.schoolClass = schoolClass
        modelContext.insert(record)

        fetchAttendanceRecords()
        sendAttendanceRecordToAPI(record: record)

        return true
    }

    func hasSigned(for schoolClass: SchoolClass) -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return attendanceRecords.contains { record in
            record.schoolClass?.id == schoolClass.id &&
            Calendar.current.isDate(record.timestamp, inSameDayAs: today)
        }
    }

    func getAttendanceForDate(_ date: Date) -> AttendanceRecord? {
        let calendar = Calendar.current
        return attendanceRecords.first { record in
            calendar.isDate(record.timestamp, inSameDayAs: date)
        }
    }

    func getMonthlyAttendance() -> String {
        // Safety check - return default if not ready
        guard self.modelContext != nil else { return "0/0" }
        
        let calendar = Calendar.current
        let now = Date()
        guard let month = calendar.dateInterval(of: .month, for: now) else { return "0/0" }

        let (scheduled, attended) = scheduledVsAttendedDates(in: month)
        return "\(attended.count)/\(scheduled.count)"
    }

    func getTotalAttendanceDays() -> Int {
        // Safety check - return default if not ready
        guard self.modelContext != nil else { return 0 }
        
        let interval = overallScheduleInterval()
        let (_, attended) = scheduledVsAttendedDates(in: interval)
        return attended.count
    }

    func getCurrentStreak() -> Int {
        // Safety check - return default if not ready
        guard self.modelContext != nil else { return 0 }
        
        let calendar = Calendar.current
        let classes = fetchAllClasses(modelContext: self.modelContext!)
        guard !classes.isEmpty else { return 0 }

        let today = calendar.startOfDay(for: Date())
        let minDate = classes.map { $0.startDate }.filter { $0 > Date(timeIntervalSince1970: 0) }.min() ?? today
        let interval = DateInterval(start: minDate, end: today)
        let (scheduled, attended) = scheduledVsAttendedDates(in: interval)
        guard !scheduled.isEmpty else { return 0 }

        let sortedScheduled = scheduled.filter { $0 <= today }.sorted(by: >)
        var streak = 0
        for date in sortedScheduled {
            if attended.contains(date) {
                streak += 1
            } else if streak > 0 || date == sortedScheduled.first {
                break
            }
        }
        return streak
    }

    // MARK: - SwiftData fetch
    private func fetchAttendanceRecords() {
        guard let modelContext else { return }

        let predicate: Predicate<AttendanceRecord>
        if let currentUserId {
            predicate = #Predicate { $0.userId == currentUserId }
        } else {
            predicate = #Predicate { _ in true }
        }

        let descriptor = FetchDescriptor<AttendanceRecord>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        do {
            attendanceRecords = try modelContext.fetch(descriptor)
        } catch {
            print("SwiftData fetch failed: \(error)")
        }
        DispatchQueue.main.async { self.onFetchFinished() }
    }

    // MARK: - Helpers for scheduled vs attended
    private func fetchAllClasses(modelContext: ModelContext) -> [SchoolClass] {
        do {
            let descriptor = FetchDescriptor<SchoolClass>()
            let classes = try modelContext.fetch(descriptor)
            // Filter out any classes with invalid dates
            return classes.filter { 
                $0.startDate > Date(timeIntervalSince1970: 0) && 
                $0.startDate < Date(timeIntervalSince1970: 365 * 24 * 60 * 60 * 10) // 10 years from now
            }
        } catch {
            print("Error fetching classes: \(error)")
            return []
        }
    }

    private func overallScheduleInterval() -> DateInterval {
        // Safety check - return safe default if not ready
        guard self.modelContext != nil else { 
            let now = Date()
            return DateInterval(start: now, end: now) 
        }
        
        let classes = fetchAllClasses(modelContext: self.modelContext!)
        guard !classes.isEmpty else {
            let now = Date()
            return DateInterval(start: now, end: now)
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Filter out invalid dates and find the earliest valid start date
        let validStartDates = classes.map { $0.startDate }.filter { $0 > Date(timeIntervalSince1970: 0) }
        guard !validStartDates.isEmpty else {
            return DateInterval(start: now, end: now)
        }
        
        let start = validStartDates.min() ?? now
        let safeStart = calendar.startOfDay(for: start)
        
        // Ensure we don't create an invalid interval
        guard safeStart <= now else {
            return DateInterval(start: now, end: now)
        }
        
        return DateInterval(start: safeStart, end: now)
    }

    private func scheduledVsAttendedDates(in interval: DateInterval) -> (scheduled: Set<Date>, attended: Set<Date>) {
        // Safety check - return empty sets if not ready
        guard self.modelContext != nil else { return ([], []) }
        
        let calendar = Calendar.current
        let classes = fetchAllClasses(modelContext: self.modelContext!)
        guard !classes.isEmpty else { return ([], []) }

        // Build scheduled days set: days in interval that have at least one class scheduled
        var scheduledDays: Set<Date> = []
        for schoolClass in classes {
            // Ensure the date is valid
            let startDate = schoolClass.startDate
            guard startDate > Date(timeIntervalSince1970: 0) else { continue }
            
            // Ensure the date is within reasonable bounds
            let maxFutureDate = calendar.date(byAdding: .year, value: 10, to: Date()) ?? Date()
            guard startDate <= maxFutureDate else { continue }
            
            let classDay = calendar.startOfDay(for: startDate)
            if interval.contains(startDate) {
                scheduledDays.insert(classDay)
            }
        }

        // Build attended days set from attendance records intersecting scheduled days
        let attendedDays = Set(
            attendanceRecords
                .filter { 
                    let timestamp = $0.timestamp
                    guard timestamp > Date(timeIntervalSince1970: 0) else { return false }
                    
                    // Ensure the date is within reasonable bounds
                    let maxFutureDate = calendar.date(byAdding: .year, value: 10, to: Date()) ?? Date()
                    guard timestamp <= maxFutureDate else { return false }
                    
                    return interval.contains(timestamp)
                }
                .compactMap { record in
                    let timestamp = record.timestamp
                    guard timestamp > Date(timeIntervalSince1970: 0) else { return nil }
                    
                    // Ensure the date is within reasonable bounds
                    let maxFutureDate = calendar.date(byAdding: .year, value: 10, to: Date()) ?? Date()
                    guard timestamp <= maxFutureDate else { return nil }
                    
                    return calendar.startOfDay(for: timestamp)
                }
                .filter { scheduledDays.contains($0) }
        )

        return (scheduledDays, attendedDays)
    }

    // MARK: - Network / stub
    private func sendAttendanceRecordToAPI(record: AttendanceRecord) {
#if DEBUG
        // 1-second stub for offline testing
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            DispatchQueue.main.async { self.onFetchFinished() }
        }
#else
        guard Self.isNetworkReachable() else {
            DispatchQueue.main.async { self.onFetchFinished() }
            return
        }

        guard let url = URL(string: "http://127.0.0.1:5001/debug-83098/us-central1/api/attendance"),
              let token = authToken else {
            DispatchQueue.main.async { self.onFetchFinished() }
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let classIdInt = Int(record.schoolClass?.id ?? "0") ?? 0
        let body: [String: Any] = [
            "classId": classIdInt,
            "attendanceDate": ISO8601DateFormatter().string(from: record.timestamp),
            "isPresent": true
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        config.timeoutIntervalForResource = 5
        let session = URLSession(configuration: config)

        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async { self.onFetchFinished() }
            if let e = error { print("API error: \(e.localizedDescription)") }
        }.resume()
#endif
    }

    // MARK: - Reachability helper
    private static func isNetworkReachable() -> Bool {
        let monitor = NWPathMonitor()
        let semaphore = DispatchSemaphore(value: 0)
        var reachable = false
        monitor.pathUpdateHandler = { path in
            reachable = path.status == .satisfied
            semaphore.signal()
        }
        monitor.start(queue: .global())
        semaphore.wait()
        monitor.cancel()
        return reachable
    }
}
