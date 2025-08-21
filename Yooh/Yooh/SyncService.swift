import Foundation
import FirebaseFirestore
import SwiftData

class SyncService: ObservableObject {
    static let shared = SyncService()
    private let db = Firestore.firestore()
    private let assignmentsCollection = "assignments"
    private let classesCollection = "classes"
    private let attendanceCollection = "attendance"
    private let locationsCollection = "locations"
    private var modelContext: ModelContext?
    private var currentUserId: String?
    
    @Published var isSyncing = false
    @Published var lastSyncError: String?

    private init() {
        // We'll set the model context when needed
    }
    
    // Method to set the model context from the environment
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // Method to set the current user ID
    func setCurrentUserId(_ userId: String) {
        self.currentUserId = userId
    }
    
    private func ensureModelContext() -> Bool {
        guard modelContext != nil else {
            lastSyncError = "Model context not set"
            return false
        }
        return true
    }
    
    private func ensureUserId() -> Bool {
        guard currentUserId != nil else {
            lastSyncError = "User ID not set"
            return false
        }
        return true
    }

    func syncAssignments() {
        guard ensureModelContext() && ensureUserId() else { return }

        isSyncing = true
        lastSyncError = nil

        // Fetch assignments from Firestore for current user only
        db.collection(assignmentsCollection)
            .whereField("userId", isEqualTo: currentUserId!)
            .getDocuments { [weak self] (querySnapshot, error) in
                DispatchQueue.main.async {
                    self?.isSyncing = false

                    if let error = error {
                        self?.lastSyncError = "Error getting documents: \(error.localizedDescription)"
                        print("Error getting documents: \(error)")
                    } else {
                        for document in querySnapshot!.documents {
                            do {
                                // Manual decoding without FirebaseFirestoreSwift
                                let assignmentDTO = try self?.decodeAssignmentFromDocument(document)
                                if let assignmentDTO = assignmentDTO {
                                    // Check if the assignment already exists in SwiftData
                                    let assignmentId = assignmentDTO.id
                                    let predicate = #Predicate<Assignment> { assignment in
                                        assignment.id == assignmentId
                                    }
                                    let descriptor = FetchDescriptor(predicate: predicate)
                                    if let existingAssignments = try? self?.modelContext?.fetch(descriptor), existingAssignments.isEmpty {
                                        // If it doesn't exist, create it
                                        let newAssignment = Assignment(from: assignmentDTO)
                                        self?.modelContext?.insert(newAssignment)
                                    }
                                }
                            } catch {
                                print("Error decoding assignment: \(error)")
                                self?.lastSyncError = "Error decoding assignment: \(error.localizedDescription)"
                            }
                        }

                        // Save the context after syncing
                        try? self?.modelContext?.save()
                    }
                }
            }
    }

    func createAssignment(_ assignment: Assignment) {
        // Save to Firestore
        let assignmentDTO = AssignmentDTO(from: assignment)
        let data = assignmentDTO.toFirestoreDictionary()

        // Use the local assignment ID as the document ID in Firestore
        db.collection(assignmentsCollection).document(assignment.id).setData(data) { error in
            if let error = error {
                print("Error creating assignment in Firestore: \(error)")
                DispatchQueue.main.async {
                    self.lastSyncError = "Error creating assignment in Firestore: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func updateAssignment(_ assignment: Assignment) {
        // Update in Firestore
        let assignmentDTO = AssignmentDTO(from: assignment)
        let data = assignmentDTO.toFirestoreDictionary()

        db.collection(assignmentsCollection).document(assignment.id).setData(data) { error in
            if let error = error {
                print("Error updating assignment in Firestore: \(error)")
                DispatchQueue.main.async {
                    self.lastSyncError = "Error updating assignment in Firestore: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func deleteAssignment(_ assignment: Assignment) {
        // Delete from Firestore
        db.collection(assignmentsCollection).document(assignment.id).delete { error in
            if let error = error {
                print("Error deleting assignment from Firestore: \(error)")
                DispatchQueue.main.async {
                    self.lastSyncError = "Error deleting assignment from Firestore: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // Manual decoding method
    private func decodeAssignmentFromDocument(_ document: QueryDocumentSnapshot) throws -> AssignmentDTO? {
        let data = document.data()

        // Debug: Print the actual data structure
        print("🔍 Assignment document data: \(data)")

        guard let id = data["id"] as? String,
              let userId = data["userId"] as? String,
              let title = data["title"] as? String,
              let dueDateTimestamp = data["dueDate"] as? Timestamp,
              let priorityString = data["priority"] as? String,
              let priority = Priority(rawValue: priorityString) else {
            print("❌ Missing required fields in assignment data:")
            print("   id: \(data["id"] ?? "nil")")
            print("   userId: \(data["userId"] ?? "nil")")
            print("   title: \(data["title"] ?? "nil")")
            print("   dueDate: \(data["dueDate"] ?? "nil")")
            print("   priority: \(data["priority"] ?? "nil")")
            throw NSError(domain: "AssignmentDecoding", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid assignment data"])
        }

        // Handle isCompleted as either Bool or Number (0/1)
        let isCompleted: Bool
        if let boolValue = data["isCompleted"] as? Bool {
            isCompleted = boolValue
        } else if let numberValue = data["isCompleted"] as? NSNumber {
            isCompleted = numberValue.boolValue
        } else {
            print("❌ Invalid isCompleted format: \(data["isCompleted"] ?? "nil")")
            throw NSError(domain: "AssignmentDecoding", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid assignment data"])
        }

        let details = data["details"] as? String

        return AssignmentDTO(
            id: id,
            userId: userId,
            title: title,
            dueDate: dueDateTimestamp.dateValue(),
            isCompleted: isCompleted,
            priority: priority,
            details: details
        )
    }

    // MARK: - School Classes Sync
    func syncClasses() {
        guard ensureModelContext() && ensureUserId() else { return }

        isSyncing = true
        lastSyncError = nil

        db.collection(classesCollection)
            .whereField("userId", isEqualTo: currentUserId!)
            .getDocuments { [weak self] (querySnapshot, error) in
                DispatchQueue.main.async {
                    self?.isSyncing = false

                    if let error = error {
                        self?.lastSyncError = "Error getting classes: \(error.localizedDescription)"
                        print("Error getting classes: \(error)")
                    } else {
                        for document in querySnapshot!.documents {
                            do {
                                if let classDTO = try self?.decodeClassFromDocument(document) {
                                    self?.updateOrCreateClass(with: classDTO)
                                }
                            } catch {
                                print("Error decoding class: \(error)")
                                self?.lastSyncError = "Error decoding class: \(error.localizedDescription)"
                            }
                        }

                        // Clean up duplicate classes after syncing
                        self?.performDuplicateCleanup()
                        
                        try? self?.modelContext?.save()
                    }
                }
            }
    }
    
    // MARK: - Utility Methods
    
    func cleanupDuplicateClasses() {
        performDuplicateCleanup()
    }
    
    private func performDuplicateCleanup() {
        guard let modelContext = modelContext else { return }
        
        // Get all classes for current user
        let descriptor = FetchDescriptor<SchoolClass>()
        guard let allClasses = try? modelContext.fetch(descriptor) else { return }
        
        // Group classes by title and dayOfWeek to find duplicates
        var classGroups: [String: [SchoolClass]] = [:]
        
        for schoolClass in allClasses {
            let key = "\(schoolClass.title)_\(schoolClass.dayOfWeek.rawValue)"
            if classGroups[key] == nil {
                classGroups[key] = []
            }
            classGroups[key]?.append(schoolClass)
        }
        
        // Remove duplicates, keeping only the first one
        for (key, classes) in classGroups {
            if classes.count > 1 {
                print("🧹 Found \(classes.count) duplicate classes for key: \(key)")
                
                // Sort by creation date (oldest first) and keep the first one
                let sortedClasses = classes.sorted { 
                    $0.startDate < $1.startDate 
                }
                
                // Remove all but the first class
                for i in 1..<sortedClasses.count {
                    let duplicateClass = sortedClasses[i]
                    print("🗑️ Removing duplicate class: \(duplicateClass.title) (ID: \(duplicateClass.id))")
                    modelContext.delete(duplicateClass)
                }
            }
        }
    }

    private func updateOrCreateClass(with dto: SchoolClassDTO) {
        guard let modelContext = modelContext else { return }
        let classId = dto.id
        let predicate = #Predicate<SchoolClass> { $0.id == classId }
        let descriptor = FetchDescriptor(predicate: predicate)

        do {
            if let existingClass = try modelContext.fetch(descriptor).first {
                // Update existing class
                existingClass.title = dto.title
                existingClass.startDate = dto.startDate.dateValue()
                existingClass.endDate = dto.endDate.dateValue()
                existingClass.location = dto.location
                existingClass.notes = dto.notes
                existingClass.dayOfWeek = DayOfWeek(rawValue: dto.dayOfWeek) ?? .monday
                existingClass.isRecurring = dto.isRecurring
            } else {
                // Create new class
                let newClass = SchoolClass(from: dto)
                modelContext.insert(newClass)
            }
        } catch {
            print("Error fetching or updating class: \(error)")
        }
    }

    func createClass(_ schoolClass: SchoolClass) {
        let classDTO = SchoolClassDTO(from: schoolClass)
        let data = classDTO.toDictionary()

        db.collection(classesCollection).document(schoolClass.id).setData(data) { error in
            if let error = error {
                print("Error creating class in Firestore: \(error)")
                DispatchQueue.main.async {
                    self.lastSyncError = "Error creating class in Firestore: \(error.localizedDescription)"
                }
            }
        }
    }

    func updateClass(_ schoolClass: SchoolClass) {
        let classDTO = SchoolClassDTO(from: schoolClass)
        let data = classDTO.toDictionary()

        db.collection(classesCollection).document(schoolClass.id).setData(data) { error in
            if let error = error {
                print("Error updating class in Firestore: \(error)")
                DispatchQueue.main.async {
                    self.lastSyncError = "Error updating class in Firestore: \(error.localizedDescription)"
                }
            }
        }
    }

    func deleteClass(_ schoolClass: SchoolClass) {
        db.collection(classesCollection).document(schoolClass.id).delete { error in
            if let error = error {
                print("Error deleting class from Firestore: \(error)")
                DispatchQueue.main.async {
                    self.lastSyncError = "Error deleting class from Firestore: \(error.localizedDescription)"
                }
            }
        }
    }

    private func decodeClassFromDocument(_ document: QueryDocumentSnapshot) throws -> SchoolClassDTO? {
        let data = document.data()

        // Debug: Print the actual data structure
        print("🔍 Class document data: \(data)")

        // Use document ID if id field is missing
        let id = data["id"] as? String ?? document.documentID

        guard let userId = data["userId"] as? String,
              let title = data["title"] as? String,
              let dayOfWeekString = data["dayOfWeek"] as? String else {
            print("❌ Missing required fields in class data:")
            print("   id: \(id)")
            print("   userId: \(data["userId"] ?? "nil")")
            print("   title: \(data["title"] ?? "nil")")
            print("   dayOfWeek: \(data["dayOfWeek"] ?? "nil")")
            throw NSError(domain: "ClassDecoding", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid class data"])
        }

        // Handle both Timestamp and ISO string formats for dates
        let startDate: Date
        let endDate: Date

        if let timestamp = data["startDate"] as? Timestamp {
            startDate = timestamp.dateValue()
        } else if let dateString = data["startDate"] as? String,
                  let date = ISO8601DateFormatter().date(from: dateString) {
            startDate = date
        } else {
            print("❌ Invalid startDate format: \(data["startDate"] ?? "nil")")
            throw NSError(domain: "ClassDecoding", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid class data"])
        }

        if let timestamp = data["endDate"] as? Timestamp {
            endDate = timestamp.dateValue()
        } else if let dateString = data["endDate"] as? String,
                  let date = ISO8601DateFormatter().date(from: dateString) {
            endDate = date
        } else {
            print("❌ Invalid endDate format: \(data["endDate"] ?? "nil")")
            throw NSError(domain: "ClassDecoding", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid class data"])
        }

        let location = data["location"] as? String
        let notes = data["notes"] as? String
        let isRecurring = data["isRecurring"] as? Bool ?? false
        
        // Handle createdAt timestamp
        let createdAt: Timestamp
        if let timestamp = data["createdAt"] as? Timestamp {
            createdAt = timestamp
        } else {
            // Fallback to startDate if createdAt is missing
            createdAt = Timestamp(date: startDate)
        }

        // Use the new initializer that properly handles all fields
        return SchoolClassDTO(
            id: id,
            userId: userId,
            title: title,
            startDate: Timestamp(date: startDate),
            endDate: Timestamp(date: endDate),
            location: location,
            notes: notes,
            dayOfWeek: dayOfWeekString,
            isRecurring: isRecurring,
            createdAt: createdAt
        )
    }

    // MARK: - Attendance Records Sync
    func syncAttendanceRecords() {
        guard ensureModelContext() && ensureUserId() else { return }

        isSyncing = true
        lastSyncError = nil

        db.collection(attendanceCollection)
            .whereField("userId", isEqualTo: currentUserId!)
            .getDocuments { [weak self] (querySnapshot, error) in
                DispatchQueue.main.async {
                    self?.isSyncing = false

                    if let error = error {
                        self?.lastSyncError = "Error getting attendance records: \(error.localizedDescription)"
                        print("Error getting attendance records: \(error)")
                    } else {
                        for document in querySnapshot!.documents {
                            do {
                                let attendanceDTO = try self?.decodeAttendanceFromDocument(document)
                                if let attendanceDTO = attendanceDTO {
                                    // Simple check - just insert if we have the DTO
                                    // In a real app, you might want more sophisticated duplicate checking
                                    let newRecord = AttendanceRecord(from: attendanceDTO)
                                    self?.modelContext?.insert(newRecord)
                                }
                            } catch {
                                print("Error decoding attendance record: \(error)")
                                self?.lastSyncError = "Error decoding attendance record: \(error.localizedDescription)"
                            }
                        }

                        try? self?.modelContext?.save()
                    }
                }
            }
    }

    func createAttendanceRecord(_ record: AttendanceRecord, classId: String) {
        let attendanceDTO = AttendanceRecordDTO(from: record, classId: classId)
        let data = attendanceDTO.toDictionary()

        db.collection(attendanceCollection).document(attendanceDTO.id).setData(data) { error in
            if let error = error {
                print("Error creating attendance record in Firestore: \(error)")
                DispatchQueue.main.async {
                    self.lastSyncError = "Error creating attendance record in Firestore: \(error.localizedDescription)"
                }
            }
        }
    }

    private func decodeAttendanceFromDocument(_ document: QueryDocumentSnapshot) throws -> AttendanceRecordDTO? {
        let data = document.data()

        guard let id = data["id"] as? String,
              let userId = data["userId"] as? String,
              let classId = data["classId"] as? String,
              let timestampData = data["timestamp"] as? Timestamp,
              let statusString = data["status"] as? String,
              let latitude = data["latitude"] as? Double,
              let longitude = data["longitude"] as? Double else {
            throw NSError(domain: "AttendanceDecoding", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid attendance data"])
        }

        return AttendanceRecordDTO(
            id: id,
            userId: userId,
            classId: classId,
            timestamp: timestampData,
            status: statusString,
            latitude: latitude,
            longitude: longitude,
            createdAt: Timestamp()
        )
    }

    // MARK: - Comprehensive Sync
    func syncAllData() {
        syncAssignments()
        syncClasses()
        syncAttendanceRecords()
    }
}