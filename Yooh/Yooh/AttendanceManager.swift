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

    // MARK: - Setup
    func setup(modelContext: ModelContext,
               authToken: String?,
               currentUserId: String?,
               onFetchFinished: @escaping () -> Void = {}) {
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

    // MARK: - Private helpers
    private func sendAttendanceRecordToAPI(record: AttendanceRecord) {
        guard Self.isNetworkReachable() else {
            print("Skipping API call – no network")
            return
        }

        guard let url = URL(string: "http://192.168.100.49:5001/api/attendance"),
              let token = authToken else {
            print("Invalid URL or missing token")
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
        config.timeoutIntervalForRequest  = 5
        config.timeoutIntervalForResource = 5
        let session = URLSession(configuration: config)

        session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("API Error: \(error.localizedDescription)")
                return
            }
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else {
                if let data = data,
                   let body = String(data: data, encoding: .utf8) {
                    print("API Error: \(body)")
                } else {
                    print("API Error: bad status code")
                }
                return
            }
            print("Attendance sent successfully")
        }.resume()
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
        let calendar = Calendar.current
        let now = Date()
        guard let monthInterval = calendar.dateInterval(of: .month, for: now) else { return "0/0" }
        
        let monthlyRecords = attendanceRecords.filter { record in
            monthInterval.contains(record.timestamp)
        }
        
        let attendedDays = Set(monthlyRecords.map { record in
            calendar.startOfDay(for: record.timestamp)
        }).count
        
        let totalDaysInMonth = calendar.range(of: .day, in: .month, for: now)!.count
        
        return "\(attendedDays)/\(totalDaysInMonth)"
    }

    func getTotalAttendanceDays() -> Int {
        return Set(attendanceRecords.map { record in
            Calendar.current.startOfDay(for: record.timestamp)
        }).count
    }

    func getCurrentStreak() -> Int {
        // This is a placeholder implementation.
        // A real implementation would require more complex logic.
        return 0
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
