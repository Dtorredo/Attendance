
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
    @State private var showingAddClass = false
    
    private var dayAbbreviations = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    
    var body: some View {
        VStack {
            Picker("Day", selection: $selectedDay) {
                ForEach(DayOfWeek.allCases) { day in
                    Text(day.rawValue.prefix(3).capitalized).tag(day)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            .background(Color.adaptiveBackground)
            .cornerRadius(8)
            .padding(.horizontal)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
            
            List {
                ForEach(classes.filter { $0.dayOfWeek == selectedDay }) { schoolClass in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(schoolClass.title)
                            .font(.headline)
                            .foregroundColor(themeManager.colorTheme.mainColor)
                        
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.secondary)
                            Text(schoolClass.location ?? "N/A")
                                .font(.subheadline)
                        }
                        
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.secondary)
                            Text("\(schoolClass.startDate, style: .time) - \(schoolClass.endDate, style: .time)")
                                .font(.subheadline)
                        }
                    }
                    .padding()
                    .background(Color.adaptiveSecondaryBackground)
                    .cornerRadius(12)
                    .adaptiveShadow()
                }
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
        }
        .background(Color.adaptiveBackground.edgesIgnoringSafeArea(.all))
        .navigationTitle("Class Schedule")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddClass = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(themeManager.colorTheme.mainColor)
                }
            }
        }
        .sheet(isPresented: $showingAddClass) {
            AddClassView(onAdd: {
                refreshData()
            })
            .environmentObject(themeManager)
        }
    }
    
    private func deleteClass(at offsets: IndexSet) {
        for offset in offsets {
            let schoolClass = classes.filter { $0.dayOfWeek == selectedDay }[offset]
            modelContext.delete(schoolClass)
        }
    }
    
    private func refreshData() {
        // Data is managed by @Query
    }
}

