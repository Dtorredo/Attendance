//
//  CalendarManager.swift
//  Yooh
//
//  Created by Derrick ng'ang'a on 06/08/2025.
//

import Foundation
import EventKit
import UserNotifications
import Combine

class CalendarManager: NSObject, ObservableObject {
    private let eventStore = EKEventStore()
    @Published var upcomingClasses: [ClassEvent] = []
    @Published var hasCalendarAccess = false
    @Published var hasNotificationAccess = false
    
    override init() {
        super.init()
        requestCalendarAccess()
        requestNotificationAccess()
    }
    
    // MARK: - Calendar Access
    
    func requestCalendarAccess() {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .notDetermined:
            eventStore.requestAccess(to: .event) { [weak self] granted, error in
                DispatchQueue.main.async {
                    self?.hasCalendarAccess = granted
                    if granted {
                        self?.loadUpcomingClasses()
                        self?.scheduleNotifications()
                    }
                }
            }
        case .authorized:
            hasCalendarAccess = true
            loadUpcomingClasses()
            scheduleNotifications()
        case .denied, .restricted:
            hasCalendarAccess = false
        @unknown default:
            hasCalendarAccess = false
        }
    }
    
    // MARK: - Notification Access
    
    func requestNotificationAccess() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.hasNotificationAccess = granted
            }
        }
    }
    
    // MARK: - Load Classes from Calendar
    
    func loadUpcomingClasses() {
        guard hasCalendarAccess else { return }
        
        let calendars = eventStore.calendars(for: .event)
        let schoolCalendars = calendars.filter { calendar in
            calendar.title.lowercased().contains("school") ||
            calendar.title.lowercased().contains("class") ||
            calendar.title.lowercased().contains("university") ||
            calendar.title.lowercased().contains("college")
        }
        
        // If no school calendars found, use all calendars
        let selectedCalendars = schoolCalendars.isEmpty ? calendars : schoolCalendars
        
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate) ?? startDate
        
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: selectedCalendars)
        let events = eventStore.events(matching: predicate)
        
        let classEvents = events.compactMap { event -> ClassEvent? in
            guard !event.isAllDay else { return nil }
            return ClassEvent(
                id: event.eventIdentifier ?? UUID().uuidString,
                title: event.title ?? "Class",
                startDate: event.startDate,
                endDate: event.endDate,
                location: event.location,
                notes: event.notes
            )
        }
        
        upcomingClasses = classEvents.sorted { $0.startDate < $1.startDate }
    }
    
    // MARK: - Schedule Notifications
    
    func scheduleNotifications() {
        guard hasNotificationAccess else { return }
        
        // Clear existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        for classEvent in upcomingClasses {
            scheduleNotification(for: classEvent)
        }
    }
    
    private func scheduleNotification(for classEvent: ClassEvent) {
        let content = UNMutableNotificationContent()
        content.title = "Class Reminder"
        content.body = "You have '\(classEvent.title)' starting in 1 hour. Don't forget to sign attendance!"
        content.sound = .default
        content.badge = 1
        
        // Schedule 1 hour before class
        let notificationDate = Calendar.current.date(byAdding: .hour, value: -1, to: classEvent.startDate)
        guard let triggerDate = notificationDate, triggerDate > Date() else { return }
        
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "class-\(classEvent.id)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    // MARK: - Refresh Data
    
    func refreshData() {
        loadUpcomingClasses()
        scheduleNotifications()
    }
}

// MARK: - Class Event Model

struct ClassEvent: Identifiable, Codable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let location: String?
    let notes: String?
    
    var isToday: Bool {
        Calendar.current.isDateInToday(startDate)
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: startDate)
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: startDate)
    }
}
