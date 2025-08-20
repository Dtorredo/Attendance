import SwiftUI
import SwiftData

struct AddEditAssignmentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    @Query private var classes: [SchoolClass]
    @StateObject private var syncService = SyncService.shared
    
    @State private var title: String = ""
    @State private var dueDate: Date = Date()
    @State private var priority: Priority = .medium
    @State private var selectedClass: SchoolClass?
    @State private var details: String = ""
    @State private var showingError = false
    
    var assignment: Assignment?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Assignment Details")) {
                    TextField("Title", text: $title)
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    Picker("Priority", selection: $priority) {
                        ForEach(Priority.allCases, id: \.self) { priority in
                            Text(priority.rawValue).tag(priority)
                        }
                    }
                    Picker("Class (Optional)", selection: $selectedClass) {
                        Text("None").tag(nil as SchoolClass?)
                        ForEach(classes) { schoolClass in
                            Text(schoolClass.title).tag(schoolClass as SchoolClass?)
                        }
                    }
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $details)
                        .frame(height: 150)
                }
            }
            .navigationTitle(assignment == nil ? "New Assignment" : "Edit Assignment")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") { saveAssignment() }
            )
            .onAppear(perform: loadAssignmentData)
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(syncService.lastSyncError ?? "Unknown error occurred")
            }
        }
    }
    
    private func loadAssignmentData() {
        if let assignment = assignment {
            title = assignment.title
            dueDate = assignment.dueDate
            priority = assignment.priority
            details = details.isEmpty ? (assignment.details ?? "") : details
            selectedClass = assignment.schoolClass
        }
        
        // Set the model context for the sync service
        syncService.setModelContext(modelContext)
    }
    
    private func saveAssignment() {
        if let assignment = assignment {
            // Edit existing assignment
            assignment.title = title
            assignment.dueDate = dueDate
            assignment.priority = priority
            assignment.details = details.isEmpty ? nil : details
            assignment.schoolClass = selectedClass
            
            // Update in Firebase
            syncService.updateAssignment(assignment)
        } else {
            // Create new assignment
            let newAssignment = Assignment(
                userId: "local_user",
                title: title,
                dueDate: dueDate,
                priority: priority,
                details: details.isEmpty ? nil : details,
                schoolClass: selectedClass
            )
            modelContext.insert(newAssignment)
            
            // Save to Firebase
            syncService.createAssignment(newAssignment)
        }
        
        // Save the context
        try? modelContext.save()
        
        // Show error if there was one
        if syncService.lastSyncError != nil {
            showingError = true
        } else {
            dismiss()
        }
    }
}
