//
//  AttendanceRecord.swift
//  Yooh
//
//  Created by Derrick ng'ang'a on 06/08/2025.
//

import Foundation
     import SwiftData
   
    @Model
    class AttendanceRecord {
        var userId: String  // Add user ID for isolation
        var timestamp: Date
     var status: AttendanceStatus
        var latitude: Double
        var longitude: Double

        // Relationship to SchoolClass
        @Relationship(inverse: \SchoolClass.attendanceRecord)
        var schoolClass: SchoolClass?
   
        init(userId: String, timestamp: Date, status: AttendanceStatus, latitude: Double, longitude: Double) {
            self.userId = userId
            self.timestamp = timestamp
            self.status = status
            self.latitude = latitude
            self.longitude = longitude
        }
    }
   
    // Enum for Attendance Status
    enum AttendanceStatus: String, Codable {
        case onTime
     case late
        case absent
    }
