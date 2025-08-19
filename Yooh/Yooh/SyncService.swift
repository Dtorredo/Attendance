import Foundation
import FirebaseFirestore
import SwiftData

class SyncService: ObservableObject {
    static let shared = SyncService()
    private let db = Firestore.firestore()
    private let assignmentsCollection = "assignments"
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
        let data = assignmentDTO.toDictionary()
        
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
        let data = assignmentDTO.toDictionary()
        
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
        
        guard let id = data["id"] as? String,
              let userId = data["userId"] as? String,
              let title = data["title"] as? String,
              let dueDateTimestamp = data["dueDate"] as? Timestamp,
              let isCompleted = data["isCompleted"] as? Bool,
              let priorityString = data["priority"] as? String,
              let priority = Priority(rawValue: priorityString) else {
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
            schoolClass: nil // We'll need to handle this separately if needed
        )
    }
}

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
    
    // Convert to dictionary for Firestore
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "userId": userId,
            "title": title,
            "dueDate": Timestamp(date: dueDate),
            "isCompleted": isCompleted,
            "priority": priority.rawValue
        ]
        
        if let details = details {
            dict["details"] = details
        }
        
        return dict
    }
}