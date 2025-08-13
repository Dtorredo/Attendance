//
//  ClassScheduleView.swift
//  Yooh
//
//  Created by Derrick ng'ang'a on 07/08/2025.
//

import SwiftUI
import SwiftData

struct ClassScheduleView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager
    @Query(sort: [SortDescriptor<SchoolClass>(\SchoolClass.startDate, order: .forward)]) private var classes: [SchoolClass]
    @State private var selectedDay: DayOfWeek = .monday
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Picker("Day", selection: $selectedDay) {
                    ForEach(DayOfWeek.allCases) { day in
                        Text(day.rawValue.capitalized).tag(day)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                Button("Clear Schedule") {
                    clearSchedule()
                }
                .font(.caption)
                .foregroundColor(.red)
                .padding(.bottom, 8)
                
                List {
                    ForEach(classes.filter { $0.dayOfWeek == selectedDay }) { schoolClass in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(schoolClass.title)
                                .font(.headline)
                            Text("Location: \(schoolClass.location ?? "N/A")")
                                .font(.subheadline)
                            Text("Time: \(schoolClass.startDate, style: .time) - \(schoolClass.endDate, style: .time)")
                                .font(.subheadline)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .frame(width: geometry.size.width * 0.5)
                    }
                    .onDelete(perform: deleteClass)
                    .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Class Schedule")
        }
    }
    
    private func deleteClass(at offsets: IndexSet) {
        for offset in offsets {
            let schoolClass = classes.filter { $0.dayOfWeek == selectedDay }[offset]
            modelContext.delete(schoolClass)
        }
    }
    
    private func clearSchedule() {
        do {
            try modelContext.delete(model: SchoolClass.self)
        } catch {
            print("Failed to clear schedule.")
        }
    }
}