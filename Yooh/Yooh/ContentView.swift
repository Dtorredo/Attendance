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
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        Group {
            if let userRole = authManager.userRole {
                if userRole == "lecturer" {
                    // Lecturer Dashboard
                    LecturerDashboardView()
                        .environment(\.modelContext, modelContext)
                        .environmentObject(authManager)
                } else {
                    // Student Dashboard (existing TabView)
                    StudentDashboardView(
                        locationManager: locationManager,
                        attendanceManager: attendanceManager,
                        themeManager: themeManager,
                        calendarManager: calendarManager,
                        schoolLocationManager: schoolLocationManager
                    )
                    .environment(\.modelContext, modelContext)
                    .environmentObject(authManager)
                }
            } else {
                // Loading state while fetching user role
                VStack {
                    ProgressView("Loading...")
                    Button("Log Out") {
                        authManager.logout()
                    }
                    .padding()
                }
                .onAppear {
                    // This will trigger the auth state listener to fetch the user role
                }
            }
        }
        .onAppear {
            // Centralized setup for all managers
            locationManager.setSchoolLocationManager(schoolLocationManager)
            locationManager.requestLocationPermission()
            attendanceManager.setup(modelContext: modelContext, authToken: authManager.token, currentUserId: authManager.currentUserId)
            calendarManager.setup(modelContext: modelContext)
            automaticAttendanceManager = AutomaticAttendanceManager(
                attendanceManager: attendanceManager,
                locationManager: locationManager,
                modelContext: modelContext
            )
            automaticAttendanceManager?.start()
            NotificationManager.shared.requestPermission()
        }
    }
}

// MARK: - Student Dashboard (existing TabView functionality)
struct StudentDashboardView: View {
    let locationManager: LocationManager
    let attendanceManager: AttendanceManager
    let themeManager: ThemeManager
    let calendarManager: CalendarManager
    let schoolLocationManager: SchoolLocationManager
    @EnvironmentObject var authManager: AuthManager
    
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
            .environmentObject(authManager)
            .tabItem {
                Label("Calendar", systemImage: "calendar")
            }

            // Tab 3: Assignments
            AssignmentsListView(themeManager: themeManager)
                .environmentObject(authManager)
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