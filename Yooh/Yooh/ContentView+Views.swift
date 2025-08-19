import SwiftUI

struct LocationStatusCard: View {
    @ObservedObject var locationManager: LocationManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                ZStack {
                    Circle()
                        .fill(locationManager.isWithinSchool ? statusGreenColor : statusRedColor)
                        .frame(width: 20, height: 20)
                    
                    Circle()
                        .fill((locationManager.isWithinSchool ? statusGreenColor : statusRedColor).opacity(0.3))
                        .frame(width: 40, height: 40)
                        .scaleEffect(locationManager.isWithinSchool ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: locationManager.isWithinSchool)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(locationManager.isWithinSchool ? "Within School Zone" : "Outside School Zone")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(cardPrimaryTextColor)
                    
                    Text(locationManager.isWithinSchool ? "Ready to check in" : "Move closer to school")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(cardSecondaryTextColor)
                }
                
                Spacer()
            }
            
            if let location = locationManager.currentLocation {
                Divider()
                    .background(dividerColor)
                
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Current Location")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(cardSecondaryTextColor)
                        
                        Text("Lat: \(location.coordinate.latitude, specifier: "%.6f")")
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .foregroundColor(cardPrimaryTextColor)
                        
                        Text("Lng: \(location.coordinate.longitude, specifier: "%.6f")")
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .foregroundColor(cardPrimaryTextColor)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 5) {
                        Text("Accuracy")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(cardSecondaryTextColor)
                        
                        Text("±\(Int(location.horizontalAccuracy))m")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(accentBlueColor)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(cardBackgroundMaterial)
                .shadow(color: cardShadowColor, radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - Color Properties
    
    private var statusGreenColor: Color {
        colorScheme == .dark ? Color.mint : Color.green
    }
    
    private var statusRedColor: Color {
        colorScheme == .dark ? Color.pink : Color.red
    }
    
    private var cardPrimaryTextColor: Color {
        colorScheme == .dark ? Color.white : Color.primary
    }
    
    private var cardSecondaryTextColor: Color {
        colorScheme == .dark ? Color.gray : Color.secondary
    }
    
    private var dividerColor: Color {
        colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2)
    }
    
    private var accentBlueColor: Color {
        colorScheme == .dark ? Color.cyan : Color.blue
    }
    
    private var cardBackgroundMaterial: Material {
        colorScheme == .dark ? .ultraThinMaterial : .ultraThinMaterial
    }
    
    private var cardShadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1)
    }
}

struct AttendanceButton: View {
    let hasActiveClass: Bool
    let isWithinSchool: Bool
    let hasSignedToday: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    @State private var isPressed = false
    
    var buttonText: String {
        if !hasActiveClass {
            return "No attendance to sign"
        }
        if hasSignedToday {
            return "Attendance Completed ✓"
        } else if isWithinSchool {
            return "Sign Attendance"
        } else {
            return "Move to School Zone"
        }
    }
    
    var buttonColors: [Color] {
        if !hasActiveClass {
            return colorScheme == .dark ? [Color.gray.opacity(0.6), Color.gray.opacity(0.4)] : [Color.gray, Color.gray.opacity(0.8)]
        }
        if hasSignedToday {
            return colorScheme == .dark ? [Color.mint, Color.mint.opacity(0.8)] : [Color.green, Color.green.opacity(0.8)]
        } else if isWithinSchool {
            return colorScheme == .dark ? [Color.cyan, Color.blue] : [Color.blue, Color.blue.opacity(0.8)]
        } else {
            return colorScheme == .dark ? [Color.gray.opacity(0.6), Color.gray.opacity(0.4)] : [Color.gray, Color.gray.opacity(0.8)]
        }
    }
    
    var shadowColor: Color {
        if !hasActiveClass {
            return Color.gray.opacity(0.2)
        }
        if hasSignedToday {
            return (colorScheme == .dark ? Color.mint : Color.green).opacity(0.4)
        } else if isWithinSchool {
            return (colorScheme == .dark ? Color.cyan : Color.blue).opacity(0.4)
        } else {
            return Color.gray.opacity(0.2)
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: !hasActiveClass ? "xmark.circle.fill" : (hasSignedToday ? "checkmark.circle.fill" : "location.circle.fill"))
                    .font(.system(size: 24, weight: .semibold))
                
                Text(buttonText)
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: buttonColors),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(color: shadowColor, radius: 15, x: 0, y: 8)
        }
        .disabled(!hasActiveClass || !isWithinSchool || hasSignedToday)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct StatsSection: View {
    @ObservedObject var attendanceManager: AttendanceManager

    var body: some View {
        HStack(spacing: 15) {
            StatCard(
                title: "This Month",
                value: "\(attendanceManager.getMonthlyAttendance())",
                icon: "calendar",
                color: .purple
            )

            StatCard(
                title: "Total Days",
                value: "\(attendanceManager.getTotalAttendanceDays())",
                icon: "chart.bar.fill",
                color: .orange
            )

            StatCard(
                title: "Streak",
                value: "\(attendanceManager.getCurrentStreak())",
                icon: "flame.fill",
                color: .red
            )
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(adaptedColor)
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(primaryTextColor)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardBackgroundMaterial)
                .shadow(color: shadowColor, radius: 5, x: 0, y: 2)
        )
    }
    
    private var adaptedColor: Color {
        switch color {
        case .purple:
            return colorScheme == .dark ? Color.purple.opacity(0.8) : Color.purple
        case .orange:
            return colorScheme == .dark ? Color.orange.opacity(0.9) : Color.orange
        case .red:
            return colorScheme == .dark ? Color.pink : Color.red
        default:
            return color
        }
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? Color.white : Color.primary
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.gray : Color.secondary
    }
    
    private var cardBackgroundMaterial: Material {
        colorScheme == .dark ? .ultraThinMaterial : .ultraThinMaterial
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.2) : Color.black.opacity(0.05)
    }
}

struct RecentAttendanceCard: View {
    @ObservedObject var attendanceManager: AttendanceManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Recent Activity")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(titleColor)
            
            VStack(spacing: 12) {
                if attendanceManager.attendanceRecords.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "clock.badge.questionmark")
                            .font(.system(size: 40))
                            .foregroundColor(emptyStateColor)
                        
                        Text("No attendance records yet")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(emptyStateColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                } else {
                    ForEach(Array(attendanceManager.attendanceRecords.prefix(5).enumerated()), id: \.element.id) { index, record in
                        AttendanceRow(record: record, index: index)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(cardBackgroundMaterial)
                    .shadow(color: shadowColor, radius: 10, x: 0, y: 5)
            )
        }
    }
    
    private var titleColor: Color {
        colorScheme == .dark ? Color.white : Color.white
    }
    
    private var emptyStateColor: Color {
        colorScheme == .dark ? Color.gray.opacity(0.6) : Color.gray
    }
    
    private var cardBackgroundMaterial: Material {
        colorScheme == .dark ? .ultraThinMaterial : .ultraThinMaterial
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1)
    }
}

struct AttendanceRow: View {
    let record: AttendanceRecord
    let index: Int
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(checkmarkBackgroundColor)
                    .frame(width: 40, height: 40)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(checkmarkColor)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(record.timestamp, style: .date)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(primaryTextColor)
                
                Text(record.timestamp, style: .time)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(secondaryTextColor)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 3) {
                Text("Present")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(statusColor)
                
                Text("On Time")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(secondaryTextColor)
            }
        }
        .padding(.vertical, 5)
        .opacity(1.0 - Double(index) * 0.1)
    }
    
    private var checkmarkBackgroundColor: Color {
        colorScheme == .dark ? Color.mint.opacity(0.2) : Color.green.opacity(0.2)
    }
    
    private var checkmarkColor: Color {
        colorScheme == .dark ? Color.mint : Color.green
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? Color.white : Color.primary
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.gray : Color.secondary
    }
    
    private var statusColor: Color {
        colorScheme == .dark ? Color.mint : Color.green
    }
}

struct SuccessOverlay: View {
    @Binding var isShowing: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        if isShowing {
            ZStack {
                Color.black.opacity(colorScheme == .dark ? 0.6 : 0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(successCircleColor)
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(isShowing ? 1.0 : 0.5)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isShowing)
                    
                    VStack(spacing: 8) {
                        Text("Attendance Signed!")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(overlayTextColor)
                        
                        Text("Successfully checked in")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(overlaySecondaryTextColor)
                    }
                }
                .padding(40)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(overlayBackgroundMaterial)
                )
                .scaleEffect(isShowing ? 1.0 : 0.8)
                .opacity(isShowing ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isShowing)
            }
        }
    }
    
    private var successCircleColor: Color {
        colorScheme == .dark ? Color.mint : Color.green
    }
    
    private var overlayTextColor: Color {
        colorScheme == .dark ? Color.white : Color.white
    }
    
    private var overlaySecondaryTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.8) : Color.white.opacity(0.8)
    }
    
    private var overlayBackgroundMaterial: Material {
        colorScheme == .dark ? .ultraThickMaterial : .ultraThinMaterial
    }
}
