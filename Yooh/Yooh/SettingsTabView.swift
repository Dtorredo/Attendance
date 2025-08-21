import SwiftUI

struct SettingsTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject var themeManager: ThemeManager
    @ObservedObject var schoolLocationManager: SchoolLocationManager

    var body: some View {
        NavigationView {
            ZStack {
                // Themed gradient background
                LinearGradient(
                    gradient: Gradient(colors: themeManager.isDarkMode ? [themeManager.colorTheme.mainColor.opacity(0.6), .black] : [themeManager.colorTheme.mainColor.opacity(0.8), .white]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Use the new modern SettingsView
                SettingsView(
                    themeManager: themeManager,
                    schoolLocationManager: schoolLocationManager
                )
                .environmentObject(authManager)
            }
            .navigationTitle("Settings")
        }
    }
}
