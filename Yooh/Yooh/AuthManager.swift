//
//  AuthManager.swift
//  Yooh
//
//  Created by Derrick ng'ang'a on 07/08/2025.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import FirebaseFirestore

class AuthManager: ObservableObject {
    @Published var token: String? {
        didSet { UserDefaults.standard.set(token, forKey: "authToken") }
    }
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var userRole: String? {
        didSet { UserDefaults.standard.set(userRole, forKey: "userRole") }
    }
    @Published var currentUserId: String? {
        didSet { UserDefaults.standard.set(currentUserId, forKey: "currentUserId") }
    }
    @Published var userFirstName: String? {
        didSet { UserDefaults.standard.set(userFirstName, forKey: "userFirstName") }
    }
    @Published var userLastName: String? {
        didSet { UserDefaults.standard.set(userLastName, forKey: "userLastName") }
    }
    @Published var userEmail: String? {
        didSet { UserDefaults.standard.set(userEmail, forKey: "userEmail") }
    }

    private var handle: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()

    // MARK: - Init
    init() {
        token = UserDefaults.standard.string(forKey: "authToken")
        userRole = UserDefaults.standard.string(forKey: "userRole")
        currentUserId = UserDefaults.standard.string(forKey: "currentUserId")
        userFirstName = UserDefaults.standard.string(forKey: "userFirstName")
        userLastName = UserDefaults.standard.string(forKey: "userLastName")
        userEmail = UserDefaults.standard.string(forKey: "userEmail")

        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.handleAuthChange(user: user)
        }
    }

    // MARK: - Public entry points
    func login(email: String, password: String) {
        isLoading = true
        errorMessage = nil

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = "Login failed: \(error.localizedDescription)"
                } else if let user = result?.user {
                    self?.handleAuthChange(user: user)
                }
            }
        }
    }

    func signUp(firstName: String, lastName: String,
                email: String, password: String, role: String) {
        print("🔥 Starting sign up for email: \(email)")
        isLoading = true
        errorMessage = nil

        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Sign up error: \(error.localizedDescription)")
                    self?.isLoading = false
                    self?.errorMessage = "Sign up failed: \(error.localizedDescription)"
                    return
                }

                guard let user = result?.user else {
                    print("❌ No user returned from sign up")
                    self?.isLoading = false
                    self?.errorMessage = "Sign up failed: No user created"
                    return
                }

                print("✅ User created successfully: \(user.uid)")
                self?.updateProfileAndSave(user: user,
                                           firstName: firstName,
                                           lastName: lastName,
                                           role: role)
            }
        }
    }

    func signInWithGoogle() {
        print("🔥 Google Sign-In started")

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("❌ Firebase configuration error - no client ID")
            errorMessage = "Firebase configuration error"
            return
        }

        print("✅ Client ID found: \(clientID)")
        isLoading = true
        errorMessage = nil

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        print("🔄 Presenting Google Sign-In...")
        GIDSignIn.sharedInstance.signIn(withPresenting: getRootViewController()) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Google Sign In error: \(error.localizedDescription)")
                    self?.isLoading = false
                    self?.errorMessage = "Google Sign In failed: \(error.localizedDescription)"
                    return
                }

                guard let result = result else {
                    print("❌ No result from Google Sign In")
                    self?.isLoading = false
                    self?.errorMessage = "Google Sign In failed: No result"
                    return
                }

                guard let idToken = result.user.idToken?.tokenString else {
                    print("❌ Failed to get Google ID token")
                    self?.isLoading = false
                    self?.errorMessage = "Failed to get Google ID token"
                    return
                }

                print("✅ Google Sign In successful, creating Firebase credential...")
                let credential = GoogleAuthProvider.credential(
                    withIDToken: idToken,
                    accessToken: result.user.accessToken.tokenString
                )

                Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        if let error = error {
                            print("❌ Firebase Sign In failed: \(error.localizedDescription)")
                            self?.errorMessage = "Firebase Sign In failed: \(error.localizedDescription)"
                        } else if let user = authResult?.user {
                            print("✅ Firebase Sign In successful: \(user.uid)")

                            // For Google Sign-In, create user profile if it doesn't exist
                            Task { @MainActor in
                                await self?.handleGoogleSignInUser(user)
                            }
                        }
                    }
                }
            }
        }
    }

    func logout() {
        isLoading = true
        do {
            try Auth.auth().signOut()
            isLoading = false
            errorMessage = nil
            userRole = nil
            currentUserId = nil
            userFirstName = nil
            userLastName = nil
            userEmail = nil
            token = nil
        } catch {
            isLoading = false
            errorMessage = "Sign-out error: \(error.localizedDescription)"
        }
    }

    // MARK: - Private helpers
    private func handleAuthChange(user: User?) {
        print("🔄 Auth state changed. User: \(user?.uid ?? "nil")")

        if let user = user {
            currentUserId = user.uid
            fetchTokenAndRole(for: user)

            // Trigger migration for first-time users
            Task {
                let migrationService = MigrationService.shared
                let hasUserMigrated = await migrationService.checkMigrationStatus(for: user.uid)
                if !hasUserMigrated {
                    await migrationService.migrateLocalDataToFirebase(for: user.uid)
                }
            }
        } else {
            token = nil
            userRole = nil
            currentUserId = nil
            userFirstName = nil
            userLastName = nil
            userEmail = nil
        }
    }

    private func fetchTokenAndRole(for user: User) {
        Task { @MainActor in
            do {
                let idToken = try await withTimeout(seconds: 10) {
                    try await user.getIDTokenResult().token
                }
                print("🎫 Token fetched successfully")
                token = idToken
                try await fetchUserRole(userId: user.uid)
                print("✅ Auth setup complete - should show main app now")

                // Ensure loading state is cleared
                isLoading = false
                print("🔄 Loading state cleared")
            } catch {
                print("❌ Token/role fetch failed: \(error.localizedDescription)")
                errorMessage = "Token/role fetch failed: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    private func updateProfileAndSave(user: User,
                                      firstName: String,
                                      lastName: String,
                                      role: String) {
        print("🔥 Updating profile for user: \(user.uid)")
        Task { @MainActor in
            do {
                let request = user.createProfileChangeRequest()
                request.displayName = "\(firstName) \(lastName)"
                try await withTimeout(seconds: 10) {
                    try await request.commitChanges()
                }
                print("✅ Profile updated successfully")

                try await saveUserToFirestore(
                    userId: user.uid,
                    firstName: firstName,
                    lastName: lastName,
                    email: user.email ?? "",
                    role: role
                )
                print("✅ User saved to Firestore successfully")
                isLoading = false
            } catch {
                print("❌ Profile/DB save failed: \(error.localizedDescription)")
                isLoading = false
                errorMessage = "Profile/DB save failed: \(error.localizedDescription)"
            }
        }
    }

    private func saveUserToFirestore(userId: String,
                                     firstName: String,
                                     lastName: String,
                                     email: String,
                                     role: String) async throws {
        let data: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "email": email,
            "role": role,
            "createdAt": Timestamp()
        ]
        try await withTimeout(seconds: 10) {
            try await self.db.collection("users").document(userId).setData(data)
        }
        userRole = role
        userFirstName = firstName
        userLastName = lastName
        userEmail = email
    }

    private func fetchUserRole(userId: String) async throws {
        let snapshot = try await withTimeout(seconds: 10) {
            try await self.db.collection("users").document(userId).getDocument()
        }
        
        // Check if document exists and has data
        guard snapshot.exists, let data = snapshot.data() else {
            print("⚠️ User document doesn't exist or has no data for userId: \(userId)")
            userRole = nil
            return
        }
        
        // Safely extract the role and user info
        if let role = data["role"] as? String {
            userRole = role
            print("👤 User role fetched: \(role)")
        } else {
            print("⚠️ Role field not found or invalid for userId: \(userId)")
            userRole = nil
        }
        
        // Extract user info
        if let firstName = data["firstName"] as? String {
            userFirstName = firstName
        }
        if let lastName = data["lastName"] as? String {
            userLastName = lastName
        }
        if let email = data["email"] as? String {
            userEmail = email
        }
    }

    // Handle Google Sign-In users who might not have a profile yet
    private func handleGoogleSignInUser(_ user: User) async {
        do {
            // Check if user profile exists
            let snapshot = try await db.collection("users").document(user.uid).getDocument()

            if snapshot.exists, let data = snapshot.data(), !data.isEmpty {
                print("✅ Existing Google user found")
                handleAuthChange(user: user)
            } else {
                print("🆕 New Google user - creating profile")
                // Create profile for new Google user
                let displayNameParts = user.displayName?.split(separator: " ") ?? []
                let firstName = String(displayNameParts.first ?? "User")
                let lastName = displayNameParts.count > 1 ? String(displayNameParts.dropFirst().joined(separator: " ")) : ""

                try await saveUserToFirestore(
                    userId: user.uid,
                    firstName: firstName,
                    lastName: lastName,
                    email: user.email ?? "",
                    role: "student" // Default role for Google sign-in
                )

                print("✅ Google user profile created")
                handleAuthChange(user: user)
            }
        } catch {
            print("❌ Error handling Google user: \(error.localizedDescription)")
            errorMessage = "Error setting up Google account: \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func getRootViewController() -> UIViewController {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else {
            return UIViewController()
        }
        return root
    }

    deinit {
        handle.map(Auth.auth().removeStateDidChangeListener)
    }
}

// MARK: - Timeout helper
private extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: TimeInterval) async throws {
        let nanoseconds = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: nanoseconds)
    }
}

private func withTimeout<T>(seconds: TimeInterval,
                            operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask { try await operation() }
        group.addTask {
            try await Task.sleep(seconds: seconds)
            throw URLError(.timedOut)
        }
        guard let result = try await group.next() else {
            throw URLError(.badServerResponse)
        }
        group.cancelAll()
        return result
    }
}
