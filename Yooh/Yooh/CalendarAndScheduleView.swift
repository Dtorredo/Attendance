
import SwiftUI

struct CalendarAndScheduleView: View {
    @ObservedObject var attendanceManager: AttendanceManager
    @ObservedObject var calendarManager: CalendarManager
    @ObservedObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss

    @State private var selectedView: Int = 0

    var body: some View {
        NavigationView {
            VStack {
                Picker("View", selection: $selectedView) {
                    Text("Calendar").tag(0)
                    Text("Schedule").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                if selectedView == 0 {
                    CalendarView(attendanceManager: attendanceManager, calendarManager: calendarManager)
                } else {
                    ClassScheduleView()
                        .environmentObject(themeManager)
                }
                
                Spacer()
            }
            .navigationTitle(selectedView == 0 ? "Attendance Calendar" : "Class Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
