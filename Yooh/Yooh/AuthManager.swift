//
//  AuthManager.swift
//  Yooh
//
//  Created by Derrick ng'ang'a on 07/08/2025.
//

import Foundation
import Combine

class AuthManager: ObservableObject {
    @Published var token: String? {
        didSet { UserDefaults.standard.set(token, forKey: "authToken") }
    }
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var userRole: String? {
        didSet { UserDefaults.standard.set(userRole, forKey: "userRole") }
    }

    // MARK: - Init
    init() {
        self.token = "mock_token"
        self.userRole = "student"  // Default to student
    }

    // MARK: - Public entry points
    func login(email: String, password: String) {
        isLoading = true
        errorMessage = nil

        // Simple mock authentication
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isLoading = false
            self.token = "mock_token"
            self.userRole = "student"  // Default to student for login
        }
    }

    func signUp(firstName: String, lastName: String,
                email: String, password: String, role: String) {
        isLoading = true
        errorMessage = nil

        // Simple mock registration
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isLoading = false
            self.token = "mock_token"
            self.userRole = role
        }
    }

    func signInWithGoogle() {
        isLoading = true
        errorMessage = nil

        // Simple mock Google authentication
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isLoading = false
            self.token = "mock_token"
            self.userRole = "student"  // Default to student for Google sign-in
        }
    }



    func logout() {
        self.token = nil
        self.userRole = nil
    }
}