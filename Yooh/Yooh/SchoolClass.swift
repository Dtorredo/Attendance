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
     var title: String
     var startDate: Date
     var endDate: Date
     var location: String?
     var notes: String?
    var dayOfWeek: DayOfWeek

     // Relationship to Attendance
     var attendanceRecord: AttendanceRecord?

     init(id: String, title: String, startDate: Date, endDate: Date, location: String? = nil, notes: String? = nil, dayOfWeek: DayOfWeek) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.notes = notes
        self.dayOfWeek = dayOfWeek
    }
 }
