import Foundation
import SwiftData
import FirebaseFirestore

class MigrationService: ObservableObject {
    static let shared = MigrationService()
    
    @Published var isMigrating = false
    @Published var migrationProgress: Double = 0.0
    @Published var migrationStatus = ""
    @Published var migrationError: String?
    
    private let db = Firestore.firestore()
    private var modelContext: ModelContext?
    
    private init() {}
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Main Migration Function
    func migrateLocalDataToFirebase(for userId: String) async {
        guard let modelContext = modelContext else {
            await MainActor.run {
                migrationError = "Model context not available"
            }
            return
        }
        
        await MainActor.run {
            isMigrating = true
            migrationProgress = 0.0
            migrationError = nil
            migrationStatus = "Starting migration..."
        }
        
        do {
            // Check if migration has already been completed for this user
            if await hasUserMigrated(userId: userId) {
                await MainActor.run {
                    migrationStatus = "Migration already completed"
                    isMigrating = false
                    migrationProgress = 1.0
                }
                return
            }
            
            // Step 1: Migrate Classes (33%)
            await MainActor.run { migrationStatus = "Migrating classes..." }
            try await migrateClasses(userId: userId, context: modelContext)
            await MainActor.run { migrationProgress = 0.33 }
            
            // Step 2: Migrate Assignments (66%)
            await MainActor.run { migrationStatus = "Migrating assignments..." }
            try await migrateAssignments(userId: userId, context: modelContext)
            await MainActor.run { migrationProgress = 0.66 }
            
            // Step 3: Migrate Attendance Records (100%)
            await MainActor.run { migrationStatus = "Migrating attendance records..." }
            try await migrateAttendanceRecords(userId: userId, context: modelContext)
            await MainActor.run { migrationProgress = 1.0 }
            
            // Mark migration as completed
            try await markMigrationCompleted(userId: userId)
            
            await MainActor.run {
                migrationStatus = "Migration completed successfully!"
                isMigrating = false
            }
            
        } catch {
            await MainActor.run {
                migrationError = "Migration failed: \(error.localizedDescription)"
                migrationStatus = "Migration failed"
                isMigrating = false
            }
        }
    }
    
    // MARK: - Migration Helper Functions
    
    private func migrateClasses(userId: String, context: ModelContext) async throws {
        let descriptor = FetchDescriptor<SchoolClass>()
        let classes = try context.fetch(descriptor)
        
        for schoolClass in classes {
            // Update userId if not set
            if schoolClass.userId.isEmpty {
                schoolClass.userId = userId
            }
            
            let classDTO = SchoolClassDTO(from: schoolClass)
            let data = classDTO.toDictionary()
            
            try await db.collection("classes").document(schoolClass.id).setData(data)
        }
        
        // Save updated local data
        try context.save()
    }
    
    private func migrateAssignments(userId: String, context: ModelContext) async throws {
        let descriptor = FetchDescriptor<Assignment>()
        let assignments = try context.fetch(descriptor)
        
        for assignment in assignments {
            // Update userId if not set
            if assignment.userId.isEmpty {
                assignment.userId = userId
            }
            
            let assignmentDTO = AssignmentDTO(from: assignment)
            let data = assignmentDTO.toFirestoreDictionary()
            
            try await db.collection("assignments").document(assignment.id).setData(data)
        }
        
        // Save updated local data
        try context.save()
    }
    
    private func migrateAttendanceRecords(userId: String, context: ModelContext) async throws {
        let descriptor = FetchDescriptor<AttendanceRecord>()
        let records = try context.fetch(descriptor)
        
        for record in records {
            // Update userId if not set
            if record.userId.isEmpty {
                record.userId = userId
            }
            
            // Find associated class ID
            let classId = record.schoolClass?.id ?? "unknown"
            let attendanceDTO = AttendanceRecordDTO(from: record, classId: classId)
            let data = attendanceDTO.toDictionary()
            
            try await db.collection("attendance").document(attendanceDTO.id).setData(data)
        }
        
        // Save updated local data
        try context.save()
    }
    
    private func hasUserMigrated(userId: String) async -> Bool {
        do {
            let doc = try await db.collection("migrations").document(userId).getDocument()
            return doc.exists
        } catch {
            return false
        }
    }
    
    private func markMigrationCompleted(userId: String) async throws {
        let migrationData: [String: Any] = [
            "userId": userId,
            "completedAt": Timestamp(),
            "version": "1.0"
        ]
        
        try await db.collection("migrations").document(userId).setData(migrationData)
    }
    
    // MARK: - Utility Functions
    
    func resetMigrationStatus() {
        isMigrating = false
        migrationProgress = 0.0
        migrationStatus = ""
        migrationError = nil
    }
    
    // Force re-migration (for testing purposes)
    func forceMigration(for userId: String) async {
        do {
            try await db.collection("migrations").document(userId).delete()
            await migrateLocalDataToFirebase(for: userId)
        } catch {
            await MainActor.run {
                migrationError = "Failed to reset migration: \(error.localizedDescription)"
            }
        }
    }
    
    // Check migration status
    func checkMigrationStatus(for userId: String) async -> Bool {
        return await hasUserMigrated(userId: userId)
    }
    
    // Get migration statistics
    func getMigrationStats(for userId: String) async -> [String: Int] {
        var stats: [String: Int] = [:]
        
        do {
            // Count classes
            let classesQuery = db.collection("classes").whereField("userId", isEqualTo: userId)
            let classesSnapshot = try await classesQuery.getDocuments()
            stats["classes"] = classesSnapshot.documents.count
            
            // Count assignments
            let assignmentsQuery = db.collection("assignments").whereField("userId", isEqualTo: userId)
            let assignmentsSnapshot = try await assignmentsQuery.getDocuments()
            stats["assignments"] = assignmentsSnapshot.documents.count
            
            // Count attendance records
            let attendanceQuery = db.collection("attendance").whereField("userId", isEqualTo: userId)
            let attendanceSnapshot = try await attendanceQuery.getDocuments()
            stats["attendance"] = attendanceSnapshot.documents.count
            
        } catch {
            print("Error getting migration stats: \(error)")
        }
        
        return stats
    }
}
