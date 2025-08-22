import SwiftUI

struct SchoolNameEditView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var schoolLocationManager: SchoolLocationManager
    @State private var schoolName: String
    
    init(schoolLocationManager: SchoolLocationManager, currentName: String) {
        self.schoolLocationManager = schoolLocationManager
        self._schoolName = State(initialValue: currentName)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("School Name")) {
                    TextField("Enter school name", text: $schoolName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section {
                    Button("Save Changes") {
                        saveSchoolName()
                    }
                    .disabled(schoolName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Edit School Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveSchoolName() {
        let trimmedName = schoolName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        schoolLocationManager.updateSchoolName(trimmedName)
        dismiss()
    }
}
