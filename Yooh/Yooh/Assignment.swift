import Foundation
import SwiftData

@Model
class Assignment {
    @Attribute(.unique) var id: String
    var userId: String  // Add user ID for isolation
    var title: String
    var dueDate: Date
    var isCompleted: Bool
    var priority: Priority
    var details: String?

    // Relationship to SchoolClass
    var schoolClass: SchoolClass?

    init(id: String = UUID().uuidString, userId: String, title: String, dueDate: Date, isCompleted: Bool = false, priority: Priority = .medium, details: String? = nil, schoolClass: SchoolClass? = nil) {
        self.id = id
        self.userId = userId
        self.title = title
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.priority = priority
        self.details = details
        self.schoolClass = schoolClass
    }
}

enum Priority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}
