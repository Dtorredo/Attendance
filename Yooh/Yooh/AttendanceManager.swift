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
        let cal = Calendar.current
        let now = Date()
        guard let month = cal.dateInterval(of: .month, for: now) else { return "0/0" }

        let daysAttended = Set(
            attendanceRecords
                .filter { month.contains($0.timestamp) }
                .map { cal.startOfDay(for: $0.timestamp) }
        ).count

        let daysInMonth = cal.range(of: .day, in: .month, for: now)!.count
        return "\(daysAttended)/\(daysInMonth)"
    }

    func getTotalAttendanceDays() -> Int {
        Set(attendanceRecords.map { Calendar.current.startOfDay(for: $0.timestamp) }).count
    }

    func getCurrentStreak() -> Int {
        let cal = Calendar.current
        let dates = attendanceRecords
            .map { $0.timestamp }        // <- fix here
            .map(cal.startOfDay(for:))
            .sorted(by: >)

        guard let latest = dates.first else { return 0 }

        var streak = 1
        var expected = cal.date(byAdding: .day, value: -1, to: latest)!

        for date in dates.dropFirst() {
            if date == expected {
                streak += 1
                expected = cal.date(byAdding: .day, value: -1, to: expected)!
            } else if date < expected {
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
