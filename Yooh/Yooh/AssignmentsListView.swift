import SwiftUI
import SwiftData

struct AssignmentsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Assignment.dueDate, order: .forward) private var assignments: [Assignment]
    @ObservedObject var themeManager: ThemeManager
    
    @State private var showingAddSheet = false

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
                    ForEach(assignments) { assignment in
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
                    }
                    .onDelete(perform: deleteItems)
                }
                .scrollContentBackground(.hidden) // Make list background transparent
                .navigationTitle("Assignments")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingAddSheet = true }) {
                            Label("Add Assignment", systemImage: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showingAddSheet) {
                    AddEditAssignmentView()
                }
            }
        }
    }

    private func toggleCompletion(for assignment: Assignment) {
        assignment.isCompleted.toggle()
        // SwiftData auto-saves
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(assignments[index])
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()
