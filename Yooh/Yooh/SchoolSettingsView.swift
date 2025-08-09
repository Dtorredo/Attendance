//
//  SchoolSettingsView.swift
//  Yooh
//
//  School location management interface
//

import SwiftUI
import CoreLocation

struct SchoolSettingsView: View {
    @ObservedObject var schoolLocationManager: SchoolLocationManager
    @ObservedObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    @State private var showingAddSchool = false
    
    var body: some View {
        // This view is now presented inside the SettingsTabView, which has its own NavigationView.
        // So we remove the NavigationView from here to avoid a nested one.
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: backgroundColors),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    // Current School Section
                    if let activeSchool = schoolLocationManager.activeSchoolLocation {
                        CurrentSchoolCard(school: activeSchool)
                    }
                    
                    // All Schools Section
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("All Schools")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(primaryTextColor)
                            
                            Spacer()
                            
                            Button(action: { showingAddSchool = true }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(themeManager.colorTheme.mainColor)
                            }
                        }
                        
                        if schoolLocationManager.schoolLocations.isEmpty {
                            EmptySchoolsView()
                        } else {
                            VStack(spacing: 12) {
                                ForEach(schoolLocationManager.schoolLocations) { school in
                                    SchoolLocationRow(
                                        school: school,
                                        isActive: school.id == schoolLocationManager.activeSchoolLocation?.id,
                                        onSelect: {
                                            schoolLocationManager.setActiveSchool(school)
                                        },
                                        onDelete: {
                                            schoolLocationManager.deleteSchoolLocation(school)
                                        }
                                    )
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
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .navigationTitle("School Settings")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingAddSchool) {
            AddSchoolView(schoolLocationManager: schoolLocationManager)
        }
    }
    
    // MARK: - Color Properties
    
    private var backgroundColors: [Color] {
        themeManager.isDarkMode ? [themeManager.colorTheme.mainColor.opacity(0.6), .black] : [themeManager.colorTheme.mainColor.opacity(0.8), .white]
    }
    
    private var primaryTextColor: Color {
        themeManager.isDarkMode ? .white : .primary
    }
    
    private var shadowColor: Color {
        themeManager.isDarkMode ? Color.black.opacity(0.3) : Color.black.opacity(0.1)
    }
}

struct CurrentSchoolCard: View {
    let school: SchoolLocation
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "building.2.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Active School")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(secondaryTextColor)
                    
                    Text(school.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(primaryTextColor)
                }
                
                Spacer()
            }
            
            Divider()
                .background(dividerColor)
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(title: "Address", value: school.address)
                InfoRow(title: "Radius", value: "\(Int(school.radius))m")
                InfoRow(title: "Coordinates", value: "\(school.latitude), \(school.longitude)")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: shadowColor, radius: 10, x: 0, y: 5)
        )
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

struct SchoolLocationRow: View {
    let school: SchoolLocation
    let isActive: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 15) {
            Button(action: onSelect) {
                HStack(spacing: 15) {
                    Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(isActive ? .green : .gray)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(school.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                        
                        Text(school.address)
                            .font(.system(size: 14))
                            .foregroundColor(secondaryTextColor)
                        
                        Text("\(Int(school.radius))m radius")
                            .font(.system(size: 12))
                            .foregroundColor(tertiaryTextColor)
                    }
                    
                    Spacer()
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? Color.white : Color.primary
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.gray : Color.secondary
    }
    
    private var tertiaryTextColor: Color {
        colorScheme == .dark ? Color.gray.opacity(0.7) : Color.secondary.opacity(0.7)
    }
}

struct AddSchoolView: View {
    @ObservedObject var schoolLocationManager: SchoolLocationManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var schoolName = ""
    @State private var schoolAddress = ""
    @State private var latitude = ""
    @State private var longitude = ""
    @State private var radius = "500"
    
    var body: some View {
        NavigationView {
            Form {
                Section("School Information") {
                    TextField("School Name", text: $schoolName)
                    TextField("Address", text: $schoolAddress)
                }
                
                Section("Location") {
                    TextField("Latitude", text: $latitude)
                        .keyboardType(.decimalPad)
                    TextField("Longitude", text: $longitude)
                        .keyboardType(.decimalPad)
                    TextField("Radius (meters)", text: $radius)
                        .keyboardType(.numberPad)
                }
                
                Section {
                    Button("Add School") {
                        addSchool()
                    }
                    .disabled(!isFormValid)
                }
            }
            .navigationTitle("Add School")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !schoolName.isEmpty &&
        !schoolAddress.isEmpty &&
        Double(latitude) != nil &&
        Double(longitude) != nil &&
        Double(radius) != nil
    }
    
    private func addSchool() {
        guard let lat = Double(latitude),
              let lng = Double(longitude),
              let rad = Double(radius) else { return }
        
        let newSchool = SchoolLocation(
            name: schoolName,
            address: schoolAddress,
            latitude: lat,
            longitude: lng,
            radius: rad
        )
        
        schoolLocationManager.addSchoolLocation(newSchool)
        dismiss()
    }
}

struct EmptySchoolsView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "building.2")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("No Schools Added")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(primaryTextColor)
            
            Text("Add your school location to get started")
                .font(.system(size: 14))
                .foregroundColor(secondaryTextColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? Color.white : Color.primary
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.gray : Color.secondary
    }
}