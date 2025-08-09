import SwiftUI
import CoreLocation
import SwiftData

import SwiftUI
import CoreLocation
import SwiftData

struct ContentView: View {
    // Managers that are shared across tabs
    @StateObject private var locationManager = LocationManager()
    @StateObject private var attendanceManager = AttendanceManager()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var calendarManager = CalendarManager()
    @StateObject private var schoolLocationManager = SchoolLocationManager()
    @State private var automaticAttendanceManager: AutomaticAttendanceManager?

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            // Tab 1: Main Dashboard
            MainDashboardView(
                locationManager: locationManager,
                attendanceManager: attendanceManager,
                themeManager: themeManager,
                calendarManager: calendarManager,
                schoolLocationManager: schoolLocationManager
            )
            .tabItem {
                Label("Dashboard", systemImage: "house.fill")
            }

            // Tab 2: Calendar and Schedule
            CalendarAndScheduleView(
                attendanceManager: attendanceManager,
                calendarManager: calendarManager,
                themeManager: themeManager
            )
            .tabItem {
                Label("Calendar", systemImage: "calendar")
            }

            // Tab 3: Assignments
            AssignmentsListView(themeManager: themeManager)
                .tabItem {
                    Label("Assignments", systemImage: "book.fill")
                }

            // Tab 4: Settings
            SettingsTabView(
                themeManager: themeManager,
                schoolLocationManager: schoolLocationManager
            )
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .onAppear {
            // Centralized setup for all managers
            locationManager.setSchoolLocationManager(schoolLocationManager)
            locationManager.requestLocationPermission()
            attendanceManager.setup(modelContext: modelContext)
            calendarManager.setup(modelContext: modelContext)
            automaticAttendanceManager = AutomaticAttendanceManager(
                attendanceManager: attendanceManager,
                locationManager: locationManager,
                modelContext: modelContext
            )
            automaticAttendanceManager?.start()
            NotificationManager.shared.requestPermission()

            // Configure Tab Bar for glass effect
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
            
            // Apply the appearance
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
