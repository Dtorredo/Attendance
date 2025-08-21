//
//  SchoolClass.swift
//  Yooh
//
//  Created by Derrick ng'ang'a on 06/08/2025.
//


 import Foundation
 import SwiftData

 @Model
class SchoolClass {
     @Attribute(.unique) var id: String
     var userId: String  // Add user ID for isolation
     var title: String
     var startDate: Date
     var endDate: Date
     var location: String?
     var notes: String?
    var dayOfWeek: DayOfWeek
    var isRecurring: Bool = false  // For recurring classes created by lecturers

     // Relationship to Attendance
     var attendanceRecord: AttendanceRecord?

     init(id: String, userId: String, title: String, startDate: Date, endDate: Date, location: String? = nil, notes: String? = nil, dayOfWeek: DayOfWeek, isRecurring: Bool = false) {
        self.id = id
        self.userId = userId
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.notes = notes
        self.dayOfWeek = dayOfWeek
        self.isRecurring = isRecurring
    }
 }
