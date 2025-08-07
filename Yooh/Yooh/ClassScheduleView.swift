
//
//  ClassScheduleView.swift
//  Yooh
//
//  Created by Derrick ng'ang'a on 07/08/2025.
//

import SwiftUI
import SwiftData

struct ClassScheduleView: View {
        @Query(sort: [SortDescriptor<SchoolClass>(\SchoolClass.startDate, order: .forward)]) private var classes: [SchoolClass]
    @State private var selectedDay: DayOfWeek = .monday
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Day", selection: $selectedDay) {
                    ForEach(DayOfWeek.allCases) { day in
                        Text(day.rawValue.capitalized).tag(day)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                List {
                    ForEach(classes.filter { $0.dayOfWeek == selectedDay }) { schoolClass in
                        VStack(alignment: .leading) {
                            Text(schoolClass.title)
                                .font(.headline)
                            Text("Location: \(schoolClass.location ?? "N/A")")
                                .font(.subheadline)
                            Text("Time: \(schoolClass.startDate, style: .time) - \(schoolClass.endDate, style: .time)")
                                .font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle("Class Schedule")
        }
    }
}
