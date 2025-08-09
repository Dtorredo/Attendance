//SettingsView

import SwiftUI

struct SettingsView: View {
    @ObservedObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var systemColorScheme
    
    var body: some View {
        NavigationView {
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
                        // Theme Section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Color Theme")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(primaryTextColor)
                            Picker("Color Theme", selection: $themeManager.colorTheme) {
                                ForEach(ColorTheme.allCases) { theme in
                                    Text(theme.rawValue.capitalized).tag(theme)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .shadow(color: shadowColor, radius: 10, x: 0, y: 5)
                        )

                        // Appearance Section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Appearance")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(primaryTextColor)
                            
                            VStack(spacing: 12) {
                                ThemeOptionRow(
                                    title: "System",
                                    subtitle: "Follow device settings",
                                    icon: "iphone",
                                    isSelected: themeManager.themeMode == .system,
                                    action: { themeManager.setTheme(.system) }
                                )
                                
                                ThemeOptionRow(
                                    title: "Light Mode",
                                    subtitle: "Always use light theme",
                                    icon: "sun.max.fill",
                                    isSelected: themeManager.themeMode == .light,
                                    action: { themeManager.setTheme(.light) }
                                )
                                
                                ThemeOptionRow(
                                    title: "Dark Mode",
                                    subtitle: "Always use dark theme",
                                    icon: "moon.fill",
                                    isSelected: themeManager.themeMode == .dark,
                                    action: { themeManager.setTheme(.dark) }
                                )
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .shadow(color: shadowColor, radius: 10, x: 0, y: 5)
                        )
                        
                        // App Info Section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("About")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(primaryTextColor)
                            
                            VStack(spacing: 12) {
                                InfoRow(title: "Version", value: "1.0.0")
                                InfoRow(title: "Location Radius", value: "100 meters")
                                InfoRow(title: "Developer", value: "School Attendance Team")
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
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(accentColor)
                }
            }
        }
    }
    
    // MARK: - Color Properties
    
    private var backgroundColors: [Color] {
        let color = themeManager.colorTheme.mainColor
        return themeManager.isDarkMode ? [color.opacity(0.6), .black] : [color.opacity(0.8), .white]
    }
    
    private var primaryTextColor: Color {
        themeManager.isDarkMode ? Color.white : Color.white
    }
    
    private var shadowColor: Color {
        themeManager.isDarkMode ? Color.black.opacity(0.3) : Color.black.opacity(0.1)
    }
    
    private var accentColor: Color {
        themeManager.isDarkMode ? Color.cyan : Color.white
    }
}

struct ThemeOptionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(primaryTextColor)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(secondaryTextColor)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var iconColor: Color {
        colorScheme == .dark ? Color.cyan : Color.blue
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? Color.white : Color.primary
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.gray : Color.secondary
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(primaryTextColor)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16))
                .foregroundColor(secondaryTextColor)
        }
        .padding(.vertical, 4)
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? Color.white : Color.primary
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.gray : Color.secondary
    }
}
