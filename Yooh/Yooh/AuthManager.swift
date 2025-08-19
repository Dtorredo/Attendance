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

    private var handle: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()

    // MARK: - Init
    init() {
        token       = UserDefaults.standard.string(forKey: "authToken")
        userRole    = UserDefaults.standard.string(forKey: "userRole")
        currentUserId = UserDefaults.standard.string(forKey: "currentUserId")

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
        isLoading = true
        errorMessage = nil

        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.isLoading = false
                    self?.errorMessage = "Sign up failed: \(error.localizedDescription)"
                    return
                }

                guard let user = result?.user else {
                    self?.isLoading = false
                    return
                }

                self?.updateProfileAndSave(user: user,
                                           firstName: firstName,
                                           lastName: lastName,
                                           role: role)
            }
        }
    }

    func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Firebase configuration error"
            return
        }

        isLoading = true
        errorMessage = nil

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: getRootViewController()) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.isLoading = false
                    self?.errorMessage = "Google Sign In failed: \(error.localizedDescription)"
                    return
                }

                guard
                    let result = result,
                    let idToken = result.user.idToken?.tokenString
                else {
                    self?.isLoading = false
                    self?.errorMessage = "Failed to get Google ID token"
                    return
                }

                let credential = GoogleAuthProvider.credential(
                    withIDToken: idToken,
                    accessToken: result.user.accessToken.tokenString
                )

                Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        if let error = error {
                            self?.errorMessage = "Firebase Sign In failed: \(error.localizedDescription)"
                        } else if let user = authResult?.user {
                            self?.handleAuthChange(user: user)
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
        } catch {
            isLoading = false
            errorMessage = "Sign-out error: \(error.localizedDescription)"
        }
    }

    // MARK: - Private helpers
    private func handleAuthChange(user: User?) {
        if let user = user {
            currentUserId = user.uid
            fetchTokenAndRole(for: user)
        } else {
            token = nil
            userRole = nil
            currentUserId = nil
        }
    }

    private func fetchTokenAndRole(for user: User) {
        Task { @MainActor in
            do {
                let idToken = try await withTimeout(seconds: 10) {
                    try await user.getIDTokenResult().token
                }
                token = idToken
                try await fetchUserRole(userId: user.uid)
            } catch {
                errorMessage = "Token/role fetch failed: \(error.localizedDescription)"
            }
        }
    }

    private func updateProfileAndSave(user: User,
                                      firstName: String,
                                      lastName: String,
                                      role: String) {
        Task { @MainActor in
            do {
                let request = user.createProfileChangeRequest()
                request.displayName = "\(firstName) \(lastName)"
                try await withTimeout(seconds: 10) {
                    try await request.commitChanges()
                }
                try await saveUserToFirestore(
                    userId: user.uid,
                    firstName: firstName,
                    lastName: lastName,
                    email: user.email ?? "",
                    role: role
                )
            } catch {
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
    }

    private func fetchUserRole(userId: String) async throws {
        let snapshot = try await withTimeout(seconds: 10) {
            try await self.db.collection("users").document(userId).getDocument()
        }
        userRole = snapshot.data()?["role"] as? String
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
