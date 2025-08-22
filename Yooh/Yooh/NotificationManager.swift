
//
//  NotificationManager.swift
//  Yooh
//
//  Created by Derrick ng'ang'a on 07/08/2025.
//

import Foundation
import UserNotifications
import SwiftData

struct ReminderPreferences: Codable, Equatable {
    var classEnabled: Bool
    var assignmentEnabled: Bool
    var classOffsetsMinutes: [Int]   // e.g., [60, 5]
    var assignmentOffsetsMinutes: [Int]

    static let `default` = ReminderPreferences(
        classEnabled: false,
        assignmentEnabled: false,
        classOffsetsMinutes: [],
        assignmentOffsetsMinutes: []
    )
}

class NotificationManager {
    static let shared = NotificationManager()

    private let prefsKey = "ReminderPreferences"

    private init() {}

    // MARK: - Permission
    func requestPermission(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            completion?(granted)
        }
    }

    // MARK: - Preferences
    func loadPreferences() -> ReminderPreferences {
        if let data = UserDefaults.standard.data(forKey: prefsKey),
           let decoded = try? JSONDecoder().decode(ReminderPreferences.self, from: data) {
            return decoded
        }
        return .default
    }

    func savePreferences(_ prefs: ReminderPreferences) {
        if let data = try? JSONEncoder().encode(prefs) {
            UserDefaults.standard.set(data, forKey: prefsKey)
        }
    }

    // MARK: - Scheduling API
    func rescheduleAllNotifications(modelContext: ModelContext, currentUserId: String) {
        let prefs = loadPreferences()
        if !prefs.classEnabled && !prefs.assignmentEnabled {
            removeAllRelatedNotifications()
            return
        }
        if prefs.classEnabled {
            scheduleAllClassNotifications(modelContext: modelContext, currentUserId: currentUserId, offsets: prefs.classOffsetsMinutes)
        } else {
            removeAllClassNotifications()
        }
        if prefs.assignmentEnabled {
            scheduleAllAssignmentNotifications(modelContext: modelContext, currentUserId: currentUserId, offsets: prefs.assignmentOffsetsMinutes)
        } else {
            removeAllAssignmentNotifications()
        }
    }

    // MARK: - Class notifications
    func scheduleAllClassNotifications(modelContext: ModelContext, currentUserId: String, offsets: [Int]) {
        let descriptor = FetchDescriptor<SchoolClass>()
        guard let classes = try? modelContext.fetch(descriptor) else { return }
        let upcoming = classes.filter { $0.userId == currentUserId && $0.startDate > Date() }
        removeAllClassNotifications()
        for schoolClass in upcoming {
            scheduleNotifications(for: schoolClass, offsets: offsets)
        }
    }

    private func scheduleNotifications(for schoolClass: SchoolClass, offsets: [Int]) {
        guard !offsets.isEmpty else { return }
        for minutes in offsets {
            let content = UNMutableNotificationContent()
            content.title = "Upcoming Class: \(schoolClass.title)"
            content.body = "Starts at \(formattedTime(schoolClass.startDate)). Reminder: \(minutes) min before."
            content.sound = .default

            guard let triggerDate = Calendar.current.date(byAdding: .minute, value: -minutes, to: schoolClass.startDate), triggerDate > Date() else { continue }
            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let identifier = "class_\(schoolClass.id)_m\(minutes)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error { print("Error scheduling class notif: \(error)") }
            }
        }
    }

    // MARK: - Assignment notifications
    func scheduleAllAssignmentNotifications(modelContext: ModelContext, currentUserId: String, offsets: [Int]) {
        let descriptor = FetchDescriptor<Assignment>()
        guard let assignments = try? modelContext.fetch(descriptor) else { return }
        let upcoming = assignments.filter { $0.userId == currentUserId && $0.dueDate > Date() && !$0.isCompleted }
        removeAllAssignmentNotifications()
        for assignment in upcoming {
            scheduleNotifications(for: assignment, offsets: offsets)
        }
    }

    private func scheduleNotifications(for assignment: Assignment, offsets: [Int]) {
        guard !offsets.isEmpty else { return }
        for minutes in offsets {
            let content = UNMutableNotificationContent()
            content.title = "Assignment Due: \(assignment.title)"
            content.body = "Due at \(formattedTime(assignment.dueDate)). Reminder: \(minutes) min before."
            content.sound = .default

            guard let triggerDate = Calendar.current.date(byAdding: .minute, value: -minutes, to: assignment.dueDate), triggerDate > Date() else { continue }
            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let identifier = "assignment_\(assignment.id)_m\(minutes)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error { print("Error scheduling assignment notif: \(error)") }
            }
        }
    }

    // MARK: - Cancel helpers
    func removeAllRelatedNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { reqs in
            let ids = reqs.map { $0.identifier }.filter { $0.hasPrefix("class_") || $0.hasPrefix("assignment_") }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    func removeAllClassNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { reqs in
            let ids = reqs.map { $0.identifier }.filter { $0.hasPrefix("class_") }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    func removeAllAssignmentNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { reqs in
            let ids = reqs.map { $0.identifier }.filter { $0.hasPrefix("assignment_") }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    // MARK: - Utils
    private func formattedTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: date)
    }
}
