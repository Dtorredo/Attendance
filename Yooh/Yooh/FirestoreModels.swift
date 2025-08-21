import Foundation
import FirebaseFirestore

// MARK: - User Model for Firestore
struct UserProfile: Codable {
    let id: String
    let firstName: String
    let lastName: String
    let email: String
    let role: String
    let createdAt: Timestamp
    
    init(id: String, firstName: String, lastName: String, email: String, role: String) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.role = role
        self.createdAt = Timestamp()
    }
}

// MARK: - SchoolClass Firestore Model
struct SchoolClassDTO: Codable {
    let id: String
    let userId: String
    let title: String
    let startDate: Timestamp
    let endDate: Timestamp
    let location: String?
    let notes: String?
    let dayOfWeek: String
    let isRecurring: Bool
    let createdAt: Timestamp
    
    init(from schoolClass: SchoolClass) {
        self.id = schoolClass.id
        self.userId = schoolClass.userId
        self.title = schoolClass.title
        self.startDate = Timestamp(date: schoolClass.startDate)
        self.endDate = Timestamp(date: schoolClass.endDate)
        self.location = schoolClass.location
        self.notes = schoolClass.notes
        self.dayOfWeek = schoolClass.dayOfWeek.rawValue
        self.isRecurring = schoolClass.isRecurring
        self.createdAt = Timestamp(date: schoolClass.startDate) // Use startDate as fallback
    }
    
    // Add a new initializer for creating from Firestore data
    init(id: String, userId: String, title: String, startDate: Timestamp, endDate: Timestamp, location: String?, notes: String?, dayOfWeek: String, isRecurring: Bool, createdAt: Timestamp) {
        self.id = id
        self.userId = userId
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.notes = notes
        self.dayOfWeek = dayOfWeek
        self.isRecurring = isRecurring
        self.createdAt = createdAt
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "userId": userId,
            "title": title,
            "startDate": startDate,
            "endDate": endDate,
            "dayOfWeek": dayOfWeek,
            "isRecurring": isRecurring,
            "createdAt": createdAt
        ]
        
        if let location = location {
            dict["location"] = location
        }
        
        if let notes = notes {
            dict["notes"] = notes
        }
        
        return dict
    }
}

// MARK: - AttendanceRecord Firestore Model
struct AttendanceRecordDTO: Codable {
    let id: String
    let userId: String
    let classId: String
    let timestamp: Timestamp
    let status: String
    let latitude: Double
    let longitude: Double
    let createdAt: Timestamp
    
    init(from record: AttendanceRecord, classId: String) {
        self.id = UUID().uuidString
        self.userId = record.userId
        self.classId = classId
        self.timestamp = Timestamp(date: record.timestamp)
        self.status = record.status.rawValue
        self.latitude = record.latitude
        self.longitude = record.longitude
        self.createdAt = Timestamp()
    }

    // Initializer for creating from Firestore data
    init(id: String, userId: String, classId: String, timestamp: Timestamp, status: String, latitude: Double, longitude: Double, createdAt: Timestamp) {
        self.id = id
        self.userId = userId
        self.classId = classId
        self.timestamp = timestamp
        self.status = status
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = createdAt
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "userId": userId,
            "classId": classId,
            "timestamp": timestamp,
            "status": status,
            "latitude": latitude,
            "longitude": longitude,
            "createdAt": createdAt
        ]
    }
}

// MARK: - Assignment Firestore Model (Enhanced)
extension AssignmentDTO {
    init(from assignment: Assignment) {
        self.id = assignment.id
        self.userId = assignment.userId
        self.title = assignment.title
        self.dueDate = assignment.dueDate
        self.isCompleted = assignment.isCompleted
        self.priority = assignment.priority
        self.details = assignment.details
    }
    
    func toFirestoreDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "userId": userId,
            "title": title,
            "dueDate": Timestamp(date: dueDate),
            "isCompleted": isCompleted,
            "priority": priority.rawValue,
            "createdAt": Timestamp()
        ]
        
        if let details = details {
            dict["details"] = details
        }
        
        return dict
    }
}

// MARK: - SchoolLocation Firestore Model
struct SchoolLocationDTO: Codable {
    let id: String
    let userId: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let radius: Double
    let isActive: Bool
    let createdAt: Timestamp
    
    init(from location: SchoolLocation, userId: String) {
        self.id = location.id.uuidString
        self.userId = userId
        self.name = location.name
        self.address = location.address
        self.latitude = location.latitude
        self.longitude = location.longitude
        self.radius = location.radius
        self.isActive = location.isActive
        self.createdAt = Timestamp()
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "userId": userId,
            "name": name,
            "address": address,
            "latitude": latitude,
            "longitude": longitude,
            "radius": radius,
            "isActive": isActive,
            "createdAt": createdAt
        ]
    }
}

// MARK: - Extensions for converting from Firestore
extension SchoolClass {
    convenience init(from dto: SchoolClassDTO) {
        self.init(
            id: dto.id,
            userId: dto.userId,
            title: dto.title,
            startDate: dto.startDate.dateValue(),
            endDate: dto.endDate.dateValue(),
            location: dto.location,
            notes: dto.notes,
            dayOfWeek: DayOfWeek(rawValue: dto.dayOfWeek) ?? .monday,
            isRecurring: dto.isRecurring
        )
    }
}

extension AttendanceRecord {
    convenience init(from dto: AttendanceRecordDTO) {
        self.init(
            userId: dto.userId,
            timestamp: dto.timestamp.dateValue(),
            status: AttendanceStatus(rawValue: dto.status) ?? .absent,
            latitude: dto.latitude,
            longitude: dto.longitude
        )
    }
}

extension Assignment {
    convenience init(from dto: AssignmentDTO) {
        self.init(
            id: dto.id,
            userId: dto.userId,
            title: dto.title,
            dueDate: dto.dueDate,
            isCompleted: dto.isCompleted,
            priority: dto.priority,
            details: dto.details,
            schoolClass: nil
        )
    }
}
