import SwiftUI
import CoreLocation
import SwiftData

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var attendanceManager = AttendanceManager()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var calendarManager = CalendarManager()
    @StateObject private var schoolLocationManager = SchoolLocationManager() // ✅ NEW
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingSuccess = false
    @State private var showingSettings = false
    @State private var showingCalendar = false
    @State private var showingSchoolSettings = false // ✅ NEW
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            // Dynamic Background Gradient
            LinearGradient(
                gradient: Gradient(colors: backgroundGradientColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Header Section with Calendar and Settings Buttons
                    VStack(spacing: 15) {
                        HStack {
                            Button(action: { showingCalendar = true }) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 24))
                                    .foregroundColor(primaryTextColor)
                            }
                            
                            // ✅ NEW: School Settings Button
                            Button(action: { showingSchoolSettings = true }) {
                                Image(systemName: "building.2")
                                    .font(.system(size: 24))
                                    .foregroundColor(primaryTextColor)
                            }
                            
                            Spacer()
                            
                            Button(action: { showingSettings = true }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(primaryTextColor)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: headerCircleColors),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "location.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(headerIconColor)
                        }
                        .shadow(color: shadowColor, radius: 10, x: 0, y: 5)
                        
                        VStack(spacing: 5) {
                            Text("School Attendance")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(primaryTextColor)
                            
                            // ✅ NEW: Show active school name
                            Text(schoolLocationManager.activeSchoolLocation?.name ?? "Location-Based Check-in")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(secondaryTextColor)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Status Card
                    VStack(spacing: 20) {
                        LocationStatusCard(locationManager: locationManager)
                        AttendanceButton(
                            isWithinSchool: locationManager.isWithinSchool,
                            hasSignedToday: attendanceManager.hasSignedToday(),
                            action: signAttendance
                        )
                    }
                    
                    // Stats Section
                    StatsSection(attendanceManager: attendanceManager)
                    
                    // Recent Attendance
                    RecentAttendanceCard(attendanceManager: attendanceManager)
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(themeManager: themeManager)
        }
        .sheet(isPresented: $showingCalendar) {
            CalendarView(attendanceManager: attendanceManager, calendarManager: calendarManager)
        }
        .sheet(isPresented: $showingSchoolSettings) { // ✅ NEW
            SchoolSettingsView(schoolLocationManager: schoolLocationManager)
        }
        .alert("Attendance Status", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .overlay(
            SuccessOverlay(isShowing: $showingSuccess)
        )
        .onAppear {
            // ✅ Connect the managers
            locationManager.setSchoolLocationManager(schoolLocationManager)
            locationManager.requestLocationPermission()
            attendanceManager.setup(modelContext: modelContext)
        }
    }
    
    // MARK: - Color Computed Properties (Keep all your existing color properties)
    
    private var backgroundGradientColors: [Color] {
        let currentScheme = themeManager.isDarkMode ? ColorScheme.dark : ColorScheme.light
        return currentScheme == .dark ? [
            Color(red: 0.05, green: 0.05, blue: 0.15),
            Color(red: 0.1, green: 0.1, blue: 0.25)
        ] : [
            Color(red: 0.1, green: 0.2, blue: 0.45),
            Color(red: 0.2, green: 0.4, blue: 0.8)
        ]
    }
    
    private var headerCircleColors: [Color] {
        let currentScheme = themeManager.isDarkMode ? ColorScheme.dark : ColorScheme.light
        return currentScheme == .dark ? [
            Color.white.opacity(0.15),
            Color.white.opacity(0.05)
        ] : [
            Color.white.opacity(0.3),
            Color.white.opacity(0.1)
        ]
    }
    
    private var headerIconColor: Color {
        themeManager.isDarkMode ? Color.cyan : Color.white
    }
    
    private var primaryTextColor: Color {
        themeManager.isDarkMode ? Color.white : Color.white
    }
    
    private var secondaryTextColor: Color {
        themeManager.isDarkMode ? Color.white.opacity(0.7) : Color.white.opacity(0.8)
    }
    
    private var shadowColor: Color {
        themeManager.isDarkMode ? Color.black.opacity(0.4) : Color.black.opacity(0.2)
    }
    
    private func signAttendance() {
        guard locationManager.isWithinSchool else {
            alertMessage = "You must be within school premises to sign attendance."
            showingAlert = true
            return
        }
        
        let success = attendanceManager.signAttendance(location: locationManager.currentLocation)
        if success {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showingSuccess = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showingSuccess = false
                }
            }
        } else {
            alertMessage = "You have already signed attendance today."
            showingAlert = true
        }
    }
}

// ✅ Keep ALL your existing UI components exactly as they are:
// - LocationStatusCard
// - AttendanceButton
// - StatsSection
// - StatCard
// - RecentAttendanceCard
// - AttendanceRow
// - SuccessOverlay

// (I'm not repeating them here since they're perfect as-is!)