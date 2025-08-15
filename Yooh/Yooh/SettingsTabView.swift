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

                Form {
                    Section(header: Text("Appearance")) {
                        NavigationLink(destination: SettingsView(themeManager: themeManager)) {
                            Label("Theme", systemImage: "paintbrush.fill")
                        }
                    }
                    
                    Section(header: Text("Location")) {
                        NavigationLink(destination: SchoolSettingsView(schoolLocationManager: schoolLocationManager, themeManager: themeManager)) {
                            Label("School Location", systemImage: "building.2.fill")
                        }
                    }

                    Section(header: Text("Account")) {
                        Button(action: {
                            authManager.logout()
                        }) {
                            Label("Sign Out", systemImage: "arrow.left.square.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
                .scrollContentBackground(.hidden) // Make form background transparent
            }
            .navigationTitle("Settings")
        }
    }
}
