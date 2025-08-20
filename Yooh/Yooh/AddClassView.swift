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
    @EnvironmentObject var authManager: AuthManager
    
    @State private var title = ""
    @State private var dayOfWeek = DayOfWeek.monday
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var location = ""
    
    var date: Date
    var onAdd: (() -> Void)? = nil
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Class Details")) {
                    TextField("Class Title", text: $title)
                    TextField("Location", text: $location)
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
            .onAppear(perform: setupView)
        }
    }
    
    private func setupView() {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        dayOfWeek = DayOfWeek(weekday: weekday) ?? .monday
        startTime = date
        endTime = date
    }
    
    private func addClass() {
        let newClass = SchoolClass(
            id: UUID().uuidString,
            userId: "local_user",
            title: title,
            startDate: startTime,
            endDate: endTime,
            location: location,
            dayOfWeek: dayOfWeek
        )
        modelContext.insert(newClass)
        NotificationManager.shared.scheduleNotification(for: newClass)
        onAdd?()
    }
}

enum DayOfWeek: String, CaseIterable, Identifiable, Codable {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday
    var id: Self { self }
    
    init?(weekday: Int) {
        switch weekday {
        case 1: self = .sunday
        case 2: self = .monday
        case 3: self = .tuesday
        case 4: self = .wednesday
        case 5: self = .thursday
        case 6: self = .friday
        case 7: self = .saturday
        default: return nil
        }
    }
    
    var shortName: String {
        switch self {
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        case .sunday: return "Sun"
        }
    }
}
