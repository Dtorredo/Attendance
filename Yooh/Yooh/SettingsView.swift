//SettingsView

import SwiftUI

struct SettingsView: View {
    @ObservedObject var themeManager: ThemeManager
    @ObservedObject var schoolLocationManager: SchoolLocationManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.colorScheme) var systemColorScheme
    @State private var showingSignOutAlert = false
    
    var body: some View {
        ZStack {
            backgroundView
            settingsContent
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authManager.logout()
            }
        } message: {
            Text("Are you sure you want to sign out? You'll need to sign in again to access your account.")
        }
    }
    
    // MARK: - Extracted subviews to help the type checker
    private var backgroundView: some View {
        LinearGradient(
            gradient: Gradient(colors: backgroundColors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var settingsContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                UserProfileSection(authManager: authManager, themeManager: themeManager)
                
                VStack(spacing: 20) {
                    appearanceSection
                    appSettingsSection
                    aboutSection
                    
                    SignOutSection { showingSignOutAlert = true }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                .padding(.top, 30)
            }
        }
    }
    
    private var appearanceSection: some View {
        SettingsSection(title: "Appearance", icon: "paintbrush.fill") {
            VStack(spacing: 16) {
                colorThemePicker
                Divider().background(dividerColor)
                themeModeOptions
            }
        }
    }
    
    private var colorThemePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Color Theme")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(primaryTextColor)
            Picker("Color Theme", selection: $themeManager.colorTheme) {
                ForEach(ColorTheme.allCases) { theme in
                    Text(theme.rawValue.capitalized).tag(theme)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .scaleEffect(0.9)
        }
    }
    
    private var themeModeOptions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Theme Mode")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(primaryTextColor)
            VStack(spacing: 8) {
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
    }
    
    @State private var showNotifications = false
    @State private var showSchoolSettings = false

    private var appSettingsSection: some View {
        SettingsSection(title: "App Settings", icon: "gearshape.fill") {
            VStack(spacing: 16) {
                SettingsRow(
                    title: "Notifications",
                    subtitle: "Manage push notifications",
                    icon: "bell.fill",
                    iconColor: .orange
                ) { showNotifications = true }
                Divider().background(dividerColor)
                SettingsRow(
                    title: "School Location",
                    subtitle: "View or add your school",
                    icon: "building.2.fill",
                    iconColor: .purple
                ) { showSchoolSettings = true }
            }
        }
        .sheet(isPresented: $showNotifications) {
            NotificationsSettingsView()
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showSchoolSettings) {
            SchoolSettingsView(
                schoolLocationManager: schoolLocationManager,
                themeManager: themeManager
            )
        }
    }
    
    private var aboutSection: some View {
        SettingsSection(title: "About", icon: "info.circle.fill") {
            VStack(spacing: 16) {
                InfoRow(title: "Version", value: "1.0.0", icon: "number.circle.fill")
                Divider().background(dividerColor)
                InfoRow(title: "Location Radius", value: "100 meters", icon: "location.circle.fill")
                Divider().background(dividerColor)
                InfoRow(title: "Developer", value: "School Attendance Team", icon: "person.2.circle.fill")
                Divider().background(dividerColor)
                InfoRow(title: "Support", value: "Get help", icon: "questionmark.circle.fill")
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
    
    private var dividerColor: Color {
        themeManager.isDarkMode ? Color.white.opacity(0.2) : Color.white.opacity(0.3)
    }
}

// MARK: - User Profile Section
struct UserProfileSection: View {
    @ObservedObject var authManager: AuthManager
    @ObservedObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 20) {
            // Profile Picture
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [themeManager.colorTheme.mainColor, themeManager.colorTheme.mainColor.opacity(0.7)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                    .shadow(color: shadowColor, radius: 10, x: 0, y: 5)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 35, weight: .medium))
                    .foregroundColor(.white)
            }
            
            // User Info
            VStack(alignment: .leading, spacing: 8) {
                Text(userDisplayName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(primaryTextColor)
                
                Text(userEmail)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(primaryTextColor.opacity(0.8))
                
                Text(userRole)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(accentColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(accentColor.opacity(0.2))
                    )
            }
            
            Spacer()
        }
        .padding(.vertical, 30)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(.ultraThinMaterial)
                .shadow(color: shadowColor, radius: 15, x: 0, y: 8)
        )
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var userDisplayName: String {
        // TODO: Get actual user name from AuthManager
        return "Student User"
    }
    
    private var userEmail: String {
        // TODO: Get actual user email from AuthManager
        return "student@school.edu"
    }
    
    private var userRole: String {
        return authManager.userRole?.capitalized ?? "Student"
    }
    
    private var primaryTextColor: Color {
        themeManager.isDarkMode ? Color.white : Color.white
    }
    
    private var accentColor: Color {
        themeManager.isDarkMode ? Color.cyan : Color.white
    }
    
    private var shadowColor: Color {
        themeManager.isDarkMode ? Color.black.opacity(0.3) : Color.black.opacity(0.1)
    }
}

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            
            content
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Sign Out Section
struct SignOutSection: View {
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Button(action: action) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.left.square.fill")
                        .font(.system(size: 20, weight: .semibold))
                    
                    Text("Sign Out")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.red, Color.red.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Text("You'll need to sign in again to access your account")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Theme Option Row
struct ThemeOptionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var iconColor: Color {
        Color.cyan
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let title: String
    let value: String
    var icon: String? = nil
    
    init(title: String, value: String, icon: String? = nil) {
        self.title = title
        self.value = value
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: 15) {
            if let iconName = icon {
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.cyan)
                    .frame(width: 24)
            }
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.vertical, 4)
    }
}
