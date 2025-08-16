import Foundation
import Combine
import CoreLocation
import SwiftData

class AttendanceManager: ObservableObject {
    @Published var attendanceRecords: [AttendanceRecord] = []
    private var modelContext: ModelContext? = nil
    private var authToken: String?

    func setup(modelContext: ModelContext, authToken: String?) {
        self.modelContext = modelContext
        self.authToken = authToken
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
        fetchAttendanceRecords() // This will update the UI

        // After saving locally, send to the backend
        sendAttendanceRecordToAPI(record: newRecord)

        return true
    }

    private func sendAttendanceRecordToAPI(record: AttendanceRecord) {
        guard let url = URL(string: "http://192.168.100.49:5001/api/attendance") else {
            print("Invalid URL")
            return
        }

        guard let token = self.authToken else {
            print("User not authenticated")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        // The backend expects an Int for classId, but the model has a String.
        // This needs to be handled properly. For now, we attempt a conversion.
        let classIdInt = Int(record.schoolClass?.id ?? "0") ?? 0

        // Prepare the data to be sent
        let body: [String: Any] = [
            "classId": classIdInt,
            "attendanceDate": ISO8601DateFormatter().string(from: record.timestamp),
            "isPresent": true
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("API Error: \(error.localizedDescription)")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                if let data = data, let responseBody = String(data: data, encoding: .utf8) {
                    print("API Error: Invalid response - \(responseBody)")
                } else {
                    print("API Error: Invalid response")
                }
                return
            }
            print("Attendance record successfully sent to API.")
        }.resume()
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
        let descriptor = FetchDescriptor<AttendanceRecord>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        do {
            attendanceRecords = try modelContext.fetch(descriptor)
        } catch {
            print("Fetch failed")
        }
    }
}