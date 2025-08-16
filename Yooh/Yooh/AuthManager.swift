import Foundation
import Combine
import FirebaseAuth
import FirebaseCore
import GoogleSignIn

class AuthManager: ObservableObject {
    @Published var token: String? {
        didSet {
            UserDefaults.standard.set(token, forKey: "authToken")
        }
    }
    @Published var errorMessage: String?

    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        self.token = UserDefaults.standard.string(forKey: "authToken")
        handle = Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            if let user = user {
                self?.token = user.uid
            } else {
                self?.token = nil
            }
        }
    }

    func login(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] (authResult, error) in
            if let error = error {
                self?.errorMessage = "Login failed: \(error.localizedDescription)"
            } else {
                self?.errorMessage = nil
            }
        }
    }

    func signUp(firstName: String, lastName: String, email: String, password: String, role: String) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] (authResult, error) in
            if let error = error {
                self?.errorMessage = "Sign up failed: \(error.localizedDescription)"
            } else {
                let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                changeRequest?.displayName = "\(firstName) \(lastName)"
                changeRequest?.commitChanges { (error) in
                    if let error = error {
                        self?.errorMessage = "Failed to update display name: \(error.localizedDescription)"
                    }
                }
                self?.errorMessage = nil
            }
        }
    }

    func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: self.getRootViewController()) { [weak self] (result, error) in
            if let error = error {
                self?.errorMessage = "Google Sign In failed: \(error.localizedDescription)"
                return
            }

            guard
                let result = result,
                let idToken = result.user.idToken?.tokenString
            else {
                return
            }

            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                             accessToken: result.user.accessToken.tokenString)

            Auth.auth().signIn(with: credential) { (authResult, error) in
                if let error = error {
                    self?.errorMessage = "Firebase Sign In failed: \(error.localizedDescription)"
                } else {
                    self?.errorMessage = nil
                }
            }
        }
    }

    func logout() {
        do {
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
            self.errorMessage = "Error signing out: \(signOutError.localizedDescription)"
        }
    }

    deinit {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    private func getRootViewController() -> UIViewController {
        guard let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return .init()
        }

        guard let root = screen.windows.first?.rootViewController else {
            return .init()
        }

        return root
    }
}