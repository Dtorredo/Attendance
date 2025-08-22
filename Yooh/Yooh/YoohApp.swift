import SwiftUI
import SwiftData
import Firebase

@main
struct YoohApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authManager = AuthManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([SchoolClass.self, AttendanceRecord.self, Assignment.self])
        
        // First, try to create a container with migration
        let migrationConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [migrationConfig])
        } catch {
            print("Migration failed: \(error)")
            
            // If migration fails, completely clear all SwiftData files and start fresh
            do {
                clearAllSwiftDataFilesInline()
                print("Cleared all SwiftData files, creating fresh container")
                
                let freshConfig = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    allowsSave: true
                )
                return try ModelContainer(for: schema, configurations: [freshConfig])
            } catch {
                print("Persistent storage failed, falling back to in-memory mode")
                
                // Last resort: use in-memory storage (data will be lost when app closes)
                let inMemoryConfig = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: true
                )
                
                do {
                    return try ModelContainer(for: schema, configurations: [inMemoryConfig])
                } catch {
                    fatalError("Could not create ModelContainer in any mode: \(error)")
                }
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            if authManager.token != nil {
                ContentView()
                    .environmentObject(authManager)
                    .onAppear {
                        print("🏠 Showing ContentView - user is authenticated")
                        // Set up services with model context
                        let context = sharedModelContainer.mainContext
                        SyncService.shared.setModelContext(context)
                        MigrationService.shared.setModelContext(context)
                        // Notification permission and scheduling
                        if let userId = authManager.currentUserId {
                            NotificationManager.shared.requestPermission { _ in
                                NotificationManager.shared.rescheduleAllNotifications(modelContext: context, currentUserId: userId)
                            }
                        }
                    }
            } else {
                LoginView()
                    .environmentObject(authManager)
                    .onAppear {
                        print("🔐 Showing LoginView - user not authenticated")
                        print("📊 Auth state - token: \(authManager.token != nil ? "exists" : "nil"), userRole: \(authManager.userRole ?? "nil"), isLoading: \(authManager.isLoading)")
                        // Set up services with model context
                        let context = sharedModelContainer.mainContext
                        SyncService.shared.setModelContext(context)
                        MigrationService.shared.setModelContext(context)
                    }
            }
        }
        .modelContainer(sharedModelContainer)
    }
    
    // Static function to clear all SwiftData files
    private static func clearAllSwiftDataFilesInline() {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // List of possible SwiftData file names
        let swiftDataFiles = [
            "default.store",
            "default.store-shm",
            "default.store-wal",
            "default.store-journal"
        ]
        
        for fileName in swiftDataFiles {
            let fileURL = documentsPath.appendingPathComponent(fileName)
            if fileManager.fileExists(atPath: fileURL.path) {
                do {
                    try fileManager.removeItem(at: fileURL)
                    print("Removed SwiftData file: \(fileName)")
                } catch {
                    print("Failed to remove \(fileName): \(error)")
                }
            }
        }
        
        // Also try to clear the Library/Application Support directory
        if let appSupportPath = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let appSupportURL = appSupportPath.appendingPathComponent("default.store")
            if fileManager.fileExists(atPath: appSupportURL.path) {
                do {
                    try fileManager.removeItem(at: appSupportURL)
                    print("Removed SwiftData file from Application Support")
                } catch {
                    print("Failed to remove from Application Support: \(error)")
                }
            }
        }
    }
}
