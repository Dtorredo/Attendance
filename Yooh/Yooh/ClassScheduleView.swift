
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
    @EnvironmentObject var authManager: AuthManager
    @Query var classes: [SchoolClass]
    @State private var selectedDay: DayOfWeek = .monday
    
    init() {
        // This initializer is intentionally left empty.
        // The view will be re-initialized when the authManager is available.
    }

    init(authManager: AuthManager) {
        let currentUserID = authManager.currentUserId ?? ""
        _classes = Query(
            filter: #Predicate<SchoolClass> { $0.userId == currentUserID },
            sort: [SortDescriptor<SchoolClass>(\SchoolClass.startDate, order: .forward)]
        )
    }
    
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
                
                if classes.filter({ $0.dayOfWeek == selectedDay }).isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)

                        Text("No classes scheduled")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)

                        Text("Classes will appear here when your lecturer assigns them")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    List {
                        ForEach(classes.filter { $0.dayOfWeek == selectedDay }) { schoolClass in
                            ClassScheduleCard(schoolClass: schoolClass)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Class Schedule")
        }
    }
}

// MARK: - ClassScheduleCard
struct ClassScheduleCard: View {
    let schoolClass: SchoolClass
    @Environment(\.colorScheme) var colorScheme

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with class title and type
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(schoolClass.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    if schoolClass.isRecurring {
                        HStack(spacing: 4) {
                            Image(systemName: "repeat")
                                .font(.caption)
                            Text("Recurring")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                    }
                }

                Spacer()

                Image(systemName: "book.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }

            // Time and location details
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.orange)
                        .frame(width: 16)

                    Text("\(timeFormatter.string(from: schoolClass.startDate)) - \(timeFormatter.string(from: schoolClass.endDate))")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }

                if let location = schoolClass.location, !location.isEmpty {
                    HStack {
                        Image(systemName: "location")
                            .foregroundColor(.green)
                            .frame(width: 16)

                        Text(location)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }

                if let notes = schoolClass.notes, !notes.isEmpty {
                    HStack(alignment: .top) {
                        Image(systemName: "note.text")
                            .foregroundColor(.purple)
                            .frame(width: 16)

                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 6, x: 0, y: 3)
        )
        .padding(.horizontal, 4)
    }
}

#Preview {
    ClassScheduleView()
        .modelContainer(for: SchoolClass.self, inMemory: true)
        .environmentObject(ThemeManager())
}
