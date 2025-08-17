import Foundation

struct AssignmentDTO {
    var id: String
    var userId: String
    var title: String
    var dueDate: Date
    var isCompleted: Bool
    var priority: Priority
    var details: String?
    
    init(id: String, userId: String, title: String, dueDate: Date, isCompleted: Bool, priority: Priority, details: String?) {
        self.id = id
        self.userId = userId
        self.title = title
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.priority = priority
        self.details = details
    }
}