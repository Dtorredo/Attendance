import SwiftUI
import SwiftData

struct AssignmentsListView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authManager: AuthManager
    @Query private var assignments: [Assignment]
    @ObservedObject var themeManager: ThemeManager
    @StateObject private var syncService = SyncService.shared
    
    @State private var showingAddSheet = false
    @State private var showingError = false

    var body: some View {
        NavigationView {
            ZStack {
                // Themed gradient background
                LinearGradient(
                    gradient: Gradient(colors: themeManager.isDarkMode ? [themeManager.colorTheme.mainColor.opacity(0.6), .black] : [themeManager.colorTheme.mainColor.opacity(0.8), .white]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                List {
                    ForEach(filteredAssignments) { assignment in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(assignment.title)
                                    .font(.headline)
                                Text("Due: \(assignment.dueDate, formatter: itemFormatter)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                if let className = assignment.schoolClass?.title {
                                    Text(className)
                                        .font(.caption)
                                        .padding(4)
                                        .background(Color.blue.opacity(0.2))
                                        .cornerRadius(4)
                                }
                            }
                            Spacer()
                            Button(action: {
                                toggleCompletion(for: assignment)
                            }) {
                                Image(systemName: assignment.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(assignment.isCompleted ? .green : .gray)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                    }
                    .onDelete(perform: deleteItems)
                }
                .scrollContentBackground(.hidden) // Make list background transparent
                .navigationTitle("Assignments")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: syncAssignments) {
                            Label("Sync", systemImage: "arrow.clockwise")
                        }
                        .disabled(syncService.isSyncing)
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingAddSheet = true }) {
                            Label("Add Assignment", systemImage: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showingAddSheet) {
                    AddEditAssignmentView()
                        .environment(\.modelContext, self.modelContext)
                        .environmentObject(authManager)
                }
                .alert("Error", isPresented: $showingError) {
                    Button("OK") { }
                } message: {
                    Text(syncService.lastSyncError ?? "Unknown error occurred")
                }
                .overlay(
                    Group {
                        if syncService.isSyncing {
                            ProgressView("Syncing...")
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(10)
                        }
                    }
                )
            }
        }
        .onAppear {
            // Set the model context for the sync service
            syncService.setModelContext(modelContext)
        }
    }
    
    // Show all assignments (no user filtering)
    private var filteredAssignments: [Assignment] {
        return assignments
    }

    private func syncAssignments() {
        syncService.syncAssignments()
    }

    private func toggleCompletion(for assignment: Assignment) {
        assignment.isCompleted.toggle()
        
        // Update in Firebase
        syncService.updateAssignment(assignment)
        
        // Save the context
        try? modelContext.save()
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            let assignmentsToDelete = offsets.map { filteredAssignments[$0] }
            
            for assignment in assignmentsToDelete {
                // Delete from Firebase first
                syncService.deleteAssignment(assignment)
                
                // Then delete from SwiftData
                modelContext.delete(assignment)
            }
        }
        
        // Save the context
        try? modelContext.save()
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()
