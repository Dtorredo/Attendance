import SwiftUI
import SwiftData

struct AddEditAssignmentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var classes: [SchoolClass]
    
    @State private var title: String = ""
    @State private var dueDate: Date = Date()
    @State private var priority: Priority = .medium
    @State private var selectedClass: SchoolClass?
    @State private var details: String = ""
    
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
        }
    }
    
    private func loadAssignmentData() {
        if let assignment = assignment {
            title = assignment.title
            dueDate = assignment.dueDate
            priority = assignment.priority
            details = assignment.details ?? ""
            selectedClass = assignment.schoolClass
        }
    }
    
    private func saveAssignment() {
        if let assignment = assignment {
            // Edit existing assignment
            assignment.title = title
            assignment.dueDate = dueDate
            assignment.priority = priority
            assignment.details = details
            assignment.schoolClass = selectedClass
        } else {
            // Create new assignment
            let newAssignment = Assignment(
                title: title,
                dueDate: dueDate,
                priority: priority,
                details: details,
                schoolClass: selectedClass
            )
            modelContext.insert(newAssignment)
        }
        
        // The context is automatically saved by SwiftData
        dismiss()
    }
}
