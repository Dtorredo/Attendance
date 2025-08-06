//
//  AddClassView.swift
//  Yooh
//
//  Created by Derrick ng'ang'a on 06/08/2025.
//

import SwiftUI

struct AddClassView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var title = ""
    @State private var dayOfWeek = DayOfWeek.monday
    @State private var startTime = Date()
    @State private var endTime = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Class Details")) {
                    TextField("Class Title", text: $title)
                    Picker("Day of Week", selection: $dayOfWeek) {
                        ForEach(DayOfWeek.allCases) { day in
                            Text(day.rawValue.capitalized).tag(day)
                        }
                    }
                }
                
                Section(header: Text("Class Time")) {
                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                }
                
                Section {
                    Button("Add Class") {
                        addClass()
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .navigationTitle("Add Class")
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
        }
    }
    
    private func addClass() {
        let newClass = SchoolClass(
            id: UUID().uuidString,
            title: title,
            startDate: startTime,
            endDate: endTime,
            dayOfWeek: dayOfWeek
        )
        modelContext.insert(newClass)
    }
}

enum DayOfWeek: String, CaseIterable, Identifiable, Codable {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday
    var id: Self { self }
}
