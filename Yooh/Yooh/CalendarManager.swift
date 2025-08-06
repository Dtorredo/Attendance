//
//  CalendarManager.swift
//  Yooh
//
//  Created by Derrick ng'ang'a on 06/08/2025.
//

import Foundation
import UserNotifications
import Combine
import SwiftData

class CalendarManager: NSObject, ObservableObject {
    @Published var upcomingClasses: [SchoolClass] = []
    @Published var hasNotificationAccess = false
    private var modelContext: ModelContext? = nil

    override init() {
        super.init()
        requestNotificationAccess()
    }

    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadUpcomingClasses()
    }
    
    // MARK: - Notification Access
    
    func requestNotificationAccess() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.hasNotificationAccess = granted
            }
        }
    }
    
    // MARK: - Load Classes from SwiftData
    
    func loadUpcomingClasses() {
        guard let modelContext = modelContext else { return }
        let descriptor = FetchDescriptor<SchoolClass>(sortBy: [SortDescriptor(\SchoolClass.startDate, order: .forward)])
        do {
            upcomingClasses = try modelContext.fetch(descriptor)
        } catch {
            print("Fetch failed")
        }
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
    
    private func scheduleNotification(for classEvent: SchoolClass) {
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
