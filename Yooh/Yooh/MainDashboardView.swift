
import SwiftUI
import CoreLocation
import SwiftData

struct MainDashboardView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var attendanceManager: AttendanceManager
    @ObservedObject var themeManager: ThemeManager
    @ObservedObject var calendarManager: CalendarManager
    @ObservedObject var schoolLocationManager: SchoolLocationManager
    
    

    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingSuccess = false
    @State private var currentClass: SchoolClass?
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: themeManager.isDarkMode ? [themeManager.colorTheme.mainColor.opacity(0.6), .black] : [themeManager.colorTheme.mainColor.opacity(0.8), .white]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 30) {
                    // Header Section with Calendar and Settings Buttons
                    VStack(spacing: 15) {
                        
                        
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
                            hasActiveClass: currentClass != nil,
                            isWithinSchool: locationManager.isWithinSchool,
                            hasSignedToday: currentClass != nil ? attendanceManager.hasSigned(for: currentClass!) : false,
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
        .alert("Attendance Status", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .overlay(
            SuccessOverlay(isShowing: $showingSuccess)
        )
        .onAppear {
            fetchCurrentClass()
        }
    }
    
    // MARK: - Color Computed Properties
    
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
        guard let currentClass = currentClass else {
            alertMessage = "You do not have a lesson at this time."
            showingAlert = true
            return
        }

        guard locationManager.isWithinSchool else {
            alertMessage = "You must be within school premises to sign attendance."
            showingAlert = true
            return
        }
        
        let success = attendanceManager.signAttendance(for: currentClass, location: locationManager.currentLocation)
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
            alertMessage = "You have already signed attendance for this class today."
            showingAlert = true
        }
    }

    private func fetchCurrentClass() {
        let now = Date()
        let calendar = Calendar.current
        let currentDay = DayOfWeek(date: now)

        // 1. Fetch all classes for today
        let descriptor = FetchDescriptor<SchoolClass>(
            predicate: #Predicate { $0.dayOfWeek == currentDay }
        )

        do {
            let todaysClasses = try modelContext.fetch(descriptor)
            
            // 2. Find the currently active class based on time
            currentClass = todaysClasses.first { schoolClass in
                // Get the time components from the stored class dates
                let startTimeComponents = calendar.dateComponents([.hour, .minute], from: schoolClass.startDate)
                let endTimeComponents = calendar.dateComponents([.hour, .minute], from: schoolClass.endDate)
                
                // Create new date objects for *today* using the class's time
                let startOfToday = calendar.startOfDay(for: now)
                guard let classStartTimeToday = calendar.date(byAdding: startTimeComponents, to: startOfToday),
                      let classEndTimeToday = calendar.date(byAdding: endTimeComponents, to: startOfToday) else {
                    return false
                }
                
                // Check if the current time is within the class's time window
                return now >= classStartTimeToday && now <= classEndTimeToday
            }
        } catch {
            print("Fetch for current class failed: \(error)")
        }
    }
}
