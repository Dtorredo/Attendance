//
//  CalendarView.swift
//  Yooh
//
//  Created by Derrick ng'ang'a on 06/08/2025.
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    @ObservedObject var attendanceManager: AttendanceManager
    @ObservedObject var calendarManager: CalendarManager
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @State private var showingAddClass = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: backgroundColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    // Calendar Grid
                    CalendarGridView(
                        currentMonth: $currentMonth,
                        selectedDate: $selectedDate,
                        scheduledDates: calendarManager.scheduledDates,
                        onDateSelected: { date in
                            selectedDate = date
                            if Calendar.current.isDateInToday(date) || date > Date() { // Allow adding classes to today or future dates
                                showingAddClass = true
                            }
                        },
                        onMonthChanged: { newMonth in
                            calendarManager.refreshData(for: newMonth)
                        }
                    )
                    
                    // Selected Date Info
                    if let attendance = attendanceManager.getAttendanceForDate(selectedDate) {
                        AttendanceDetailCard(attendance: attendance)
                    } else {
                        NoAttendanceCard(date: selectedDate)
                    }
                    
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .onAppear {
            calendarManager.refreshData(for: currentMonth)
        }
        .sheet(isPresented: $showingAddClass) {
            AddClassView(date: selectedDate)
        }
    }
    
    private var backgroundColors: [Color] {
        colorScheme == .dark ? [
            Color(red: 0.05, green: 0.05, blue: 0.15),
            Color(red: 0.1, green: 0.1, blue: 0.25)
        ] : [
            Color(red: 0.1, green: 0.2, blue: 0.45),
            Color(red: 0.2, green: 0.4, blue: 0.8)
        ]
    }
    
    private var accentColor: Color {
        colorScheme == .dark ? Color.cyan : Color.white
    }
    
    
}

struct CalendarGridView: View {
    @Binding var currentMonth: Date
    @Binding var selectedDate: Date
    let scheduledDates: [Date]
    let onDateSelected: (Date) -> Void
    let onMonthChanged: (Date) -> Void
    @Environment(\.colorScheme) var colorScheme
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    private var monthDays: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else { return [] }
        
        let firstOfMonth = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let startDate = calendar.date(byAdding: .day, value: -(firstWeekday - 1), to: firstOfMonth) ?? firstOfMonth
        
        var days: [Date] = []
        for i in 0..<42 { // 6 weeks * 7 days
            if let day = calendar.date(byAdding: .day, value: i, to: startDate) {
                days.append(day)
            }
        }
        return days
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Month Navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(accentColor)
                }
                
                Spacer()
                
                Text(dateFormatter.string(from: currentMonth))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(primaryTextColor)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(accentColor)
                }
            }
            .padding(.horizontal, 20)
            
            // Weekday Headers
            HStack(spacing: 0) {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(secondaryTextColor)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(monthDays, id: \.self) { date in
                    CalendarDayView(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month),
                        hasClass: hasClass(for: date),
                        isToday: calendar.isDateInToday(date)
                    ) {
                        onDateSelected(date)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: shadowColor, radius: 10, x: 0, y: 5)
        )
    }
    
    private func hasClass(for date: Date) -> Bool {
        return scheduledDates.contains { scheduledDate in
            calendar.isDate(scheduledDate, inSameDayAs: date)
        }
    }
    
    private func previousMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
            onMonthChanged(currentMonth)
        }
    }
    
    private func nextMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
            onMonthChanged(currentMonth)
        }
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? Color.white : Color.white
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.gray : Color.gray
    }
    
    private var accentColor: Color {
        colorScheme == .dark ? Color.cyan : Color.blue
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1)
    }
}

struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isCurrentMonth: Bool
    let hasClass: Bool
    let isToday: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .frame(height: 44)
                
                // Day Number
                Text(dayNumber)
                    .font(.system(size: 16, weight: isToday ? .bold : .medium))
                    .foregroundColor(textColor)
                
                // Class Indicator
                if hasClass {
                    VStack {
                        Spacer()
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                            .offset(y: -4)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return colorScheme == .dark ? Color.cyan : Color.blue
        } else if isToday {
            return colorScheme == .dark ? Color.cyan.opacity(0.3) : Color.blue.opacity(0.3)
        } else if hasClass {
            return Color.green.opacity(0.3)
        } else {
            return Color.clear
        }
    }
    
    private var textColor: Color {
        if isSelected {
            return Color.white
        } else if !isCurrentMonth {
            return Color.gray.opacity(0.5)
        } else if isToday {
            return colorScheme == .dark ? Color.cyan : Color.blue
        } else {
            return colorScheme == .dark ? Color.white : Color.primary
        }
    }
}

struct AttendanceDetailCard: View {
    let attendance: AttendanceRecord
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(successColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Attendance Recorded")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(primaryTextColor)
                    
                    Text(attendance.timestamp, style: .time)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(secondaryTextColor)
                }
                
                Spacer()
            }
            
            Divider()
                .background(dividerColor)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Location")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(primaryTextColor)
                
                Text("Lat: \(attendance.latitude)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(secondaryTextColor)
                
                Text("Lng: \(attendance.longitude)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(secondaryTextColor)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: shadowColor, radius: 10, x: 0, y: 5)
        )
    }
    
    private var successColor: Color {
        colorScheme == .dark ? Color.mint : Color.green
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? Color.white : Color.primary
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.gray : Color.secondary
    }
    
    private var dividerColor: Color {
        colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2)
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1)
    }
}

struct NoAttendanceCard: View {
    let date: Date
    @Environment(\.colorScheme) var colorScheme
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    private var isFuture: Bool {
        date > Date()
    }
    
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: isToday ? "clock" : isFuture ? "calendar" : "xmark.circle")
                .font(.system(size: 40))
                .foregroundColor(iconColor)
            
            VStack(spacing: 8) {
                Text(titleText)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(primaryTextColor)
                
                Text(subtitleText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(secondaryTextColor)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: shadowColor, radius: 10, x: 0, y: 5)
        )
    }
    
    private var titleText: String {
        if isToday {
            return "No Attendance Today"
        } else if isFuture {
            return "Future Date"
        } else {
            return "No Attendance Recorded"
        }
    }
    
    private var subtitleText: String {
        if isToday {
            return "Remember to sign attendance when you arrive at school"
        } else if isFuture {
            return "Attendance can only be recorded on the day of class"
        } else {
            return "No attendance was recorded for this date"
        }
    }
    
    private var iconColor: Color {
        if isToday {
            return colorScheme == .dark ? Color.orange : Color.orange
        } else if isFuture {
            return colorScheme == .dark ? Color.cyan : Color.blue
        } else {
            return Color.gray
        }
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? Color.white : Color.primary
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.gray : Color.secondary
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1)
    }
}


