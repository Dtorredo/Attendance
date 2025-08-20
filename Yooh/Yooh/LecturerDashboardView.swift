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
                    
                    Button("Add New Class") {
                        // TODO: Implement add class
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Add New Assignment") {
                        // TODO: Implement add assignment
                    }
                    .buttonStyle(.borderedProminent)
                    
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
    
    // Show all data (no user filtering)
    private var filteredClasses: [SchoolClass] {
        return classes
    }

    private var filteredAssignments: [Assignment] {
        return assignments
    }
}
