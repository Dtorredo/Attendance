import SwiftUI
import SwiftData

struct LecturerDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authManager: AuthManager
    @Query private var classes: [SchoolClass]
    @Query private var assignments: [Assignment]
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Lecturer Dashboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Welcome, Lecturer!")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 20) {
                    HStack {
                        VStack {
                            Text("\(filteredClasses.count)")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Classes")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(12)
                        
                        VStack {
                            Text("\(filteredAssignments.count)")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Assignments")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(12)
                    }
                    
                    Text("Use the web dashboard to create classes and assignments")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button("Sign Out") {
                        authManager.logout()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Lecturer Dashboard")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // Filter data by current user ID
    private var filteredClasses: [SchoolClass] {
        guard let currentUserId = getCurrentUserId() else { return [] }
        return classes.filter { $0.userId == currentUserId }
    }
    
    private var filteredAssignments: [Assignment] {
        guard let currentUserId = getCurrentUserId() else { return [] }
        return assignments.filter { $0.userId == currentUserId }
    }
    
    // Get current user ID from AuthManager
    private func getCurrentUserId() -> String? {
        return authManager.currentUserId
    }
}
