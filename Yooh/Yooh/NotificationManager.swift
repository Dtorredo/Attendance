
//
//  NotificationManager.swift
//  Yooh
//
//  Created by Derrick ng'ang'a on 07/08/2025.
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted == true && error == nil {
                // We have permission
            }
        }
    }

    func scheduleNotification(for schoolClass: SchoolClass) {
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Class: \(schoolClass.title)"
        content.body = "Your class at \(schoolClass.location ?? "N/A") is starting in 15 minutes."
        content.sound = .default

        let triggerDate = Calendar.current.date(byAdding: .minute, value: -15, to: schoolClass.startDate)!
        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate), repeats: false)

        let request = UNNotificationRequest(identifier: schoolClass.id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
}
