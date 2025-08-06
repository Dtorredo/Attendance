//
//  ColorTheme.swift
//  Yooh
//
//  Created by Derrick ng'ang'a on 06/08/2025.
//
import SwiftUI

// MARK: - Theme Manager

enum ThemeMode: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

class ThemeManager: ObservableObject {
    @Published var themeMode: ThemeMode = .system
    @Published var isDarkMode: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let themeKey = "SelectedTheme"
    
    init() {
        loadTheme()
        updateTheme()
    }
    
    func setTheme(_ mode: ThemeMode) {
        themeMode = mode
        saveTheme()
        updateTheme()
        applyTheme()
    }
    
    private func loadTheme() {
        if let savedTheme = userDefaults.string(forKey: themeKey),
           let theme = ThemeMode(rawValue: savedTheme) {
            themeMode = theme
        }
    }
    
    private func saveTheme() {
        userDefaults.set(themeMode.rawValue, forKey: themeKey)
    }
    
    private func updateTheme() {
        switch themeMode {
        case .system:
            // Detect system theme
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                isDarkMode = window.traitCollection.userInterfaceStyle == .dark
            }
        case .light:
            isDarkMode = false
        case .dark:
            isDarkMode = true
        }
    }
    
    private func applyTheme() {
        let style: UIUserInterfaceStyle
        
        switch themeMode {
        case .system:
            style = .unspecified
        case .light:
            style = .light
        case .dark:
            style = .dark
        }
        
        // Apply theme to all windows
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .forEach { window in
                window.overrideUserInterfaceStyle = style
            }
    }
}

// MARK: - Color Extensions

extension Color {
    static var adaptiveBackground: Color {
        Color(UIColor.systemBackground)
    }
    
    static var adaptiveSecondaryBackground: Color {
        Color(UIColor.secondarySystemBackground)
    }
    
    static var adaptiveTertiaryBackground: Color {
        Color(UIColor.tertiarySystemBackground)
    }
    
    static var adaptiveLabel: Color {
        Color(UIColor.label)
    }
    
    static var adaptiveSecondaryLabel: Color {
        Color(UIColor.secondaryLabel)
    }
    
    static var adaptiveTertiaryLabel: Color {
        Color(UIColor.tertiaryLabel)
    }
}

// MARK: - Material Extensions

extension Material {
    static var adaptiveCard: Material {
        .ultraThinMaterial
    }
    
    static var adaptiveOverlay: Material {
        .thickMaterial
    }
}

// MARK: - Shadow Modifiers

struct AdaptiveShadow: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
    
    func body(content: Content) -> some View {
        content
            .shadow(
                color: colorScheme == .dark ? .black.opacity(0.4) : .black.opacity(0.2),
                radius: radius,
                x: x,
                y: y
            )
    }
}

extension View {
    func adaptiveShadow(radius: CGFloat = 10, x: CGFloat = 0, y: CGFloat = 5) -> some View {
        modifier(AdaptiveShadow(radius: radius, x: x, y: y))
    }
}
