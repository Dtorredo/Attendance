import SwiftUI

struct CalendarAndScheduleView: View {
    @ObservedObject var attendanceManager: AttendanceManager
    @ObservedObject var calendarManager: CalendarManager
    @ObservedObject var themeManager: ThemeManager
    @EnvironmentObject var authManager: AuthManager

    @State private var selectedView: Int = 0

    var body: some View {
        NavigationView {
            ZStack {
                // Themed gradient background that covers the whole screen
                LinearGradient(
                    gradient: Gradient(colors: themeManager.isDarkMode ? [themeManager.colorTheme.mainColor.opacity(0.6), .black] : [themeManager.colorTheme.mainColor.opacity(0.8), .white]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack {
                    // Glass container for the picker
                    VStack {
                        Picker("View", selection: $selectedView) {
                            Text("Calendar").tag(0)
                            Text("Schedule").tag(1)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal)

                    // The content being switched
                    if selectedView == 0 {
                        CalendarView(attendanceManager: attendanceManager, calendarManager: calendarManager)
                            .environmentObject(authManager)
                    } else {
                        ClassScheduleView()
                            .environmentObject(themeManager)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle(selectedView == 0 ? "Attendance Calendar" : "Class Schedule")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}