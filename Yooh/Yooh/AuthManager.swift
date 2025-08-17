import Foundation
import Combine
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import FirebaseFirestore

class AuthManager: ObservableObject {
    @Published var token: String? {
        didSet {
            UserDefaults.standard.set(token, forKey: "authToken")
        }
    }
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var userRole: String? {
        didSet {
            if let role = userRole {
                UserDefaults.standard.set(role, forKey: "userRole")
            }
        }
    }
    @Published var currentUserId: String? {
        didSet {
            if let userId = currentUserId {
                UserDefaults.standard.set(userId, forKey: "currentUserId")
            }
        }
    }

    private var handle: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()

    init() {
        self.token = UserDefaults.standard.string(forKey: "authToken")
        self.userRole = UserDefaults.standard.string(forKey: "userRole")
        self.currentUserId = UserDefaults.standard.string(forKey: "currentUserId")
        
        handle = Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            if let user = user {
                self?.currentUserId = user.uid  // Store the actual Firebase user ID
                user.getIDToken { token, error in
                    if let error = error {
                        self?.errorMessage = "Failed to get ID token: \(error.localizedDescription)"
                        self?.token = nil
                    } else if let token = token {
                        self?.token = token
                        self?.errorMessage = nil
                        // Fetch user role from Firestore
                        self?.fetchUserRole(userId: user.uid)
                    }
                }
            } else {
                self?.token = nil
                self?.errorMessage = nil
                self?.userRole = nil
                self?.currentUserId = nil
            }
        }
    }

    func login(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] (authResult, error) in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Login failed: \(error.localizedDescription)"
                } else {
                    self?.errorMessage = nil
                    // Token will be set by the auth state listener
                }
            }
        }
    }

    func signUp(firstName: String, lastName: String, email: String, password: String, role: String) {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] (authResult, error) in
            DispatchQueue.main.async {
                if let error = error {
                    self?.isLoading = false
                    self?.errorMessage = "Sign up failed: \(error.localizedDescription)"
                } else {
                    // Update display name
                    let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                    changeRequest?.displayName = "\(firstName) \(lastName)"
                    changeRequest?.commitChanges { (error) in
                        DispatchQueue.main.async {
                            if let error = error {
                                self?.isLoading = false
                                self?.errorMessage = "Account created but failed to update display name: \(error.localizedDescription)"
                            } else {
                                // Save user data to Firestore
                                if let user = Auth.auth().currentUser {
                                    self?.saveUserToFirestore(userId: user.uid, firstName: firstName, lastName: lastName, email: email, role: role)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func saveUserToFirestore(userId: String, firstName: String, lastName: String, email: String, role: String) {
        let userData: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "email": email,
            "role": role,
            "createdAt": Timestamp()
        ]
        
        db.collection("users").document(userId).setData(userData) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = "Failed to save user data: \(error.localizedDescription)"
                } else {
                    self?.errorMessage = nil
                    self?.userRole = role
                    // Token will be set by the auth state listener
                }
            }
        }
    }
    
    private func fetchUserRole(userId: String) {
        db.collection("users").document(userId).getDocument { [weak self] (document, error) in
            DispatchQueue.main.async {
                if let document = document, document.exists {
                    if let role = document.data()?["role"] as? String {
                        self?.userRole = role
                    }
                }
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

        GIDSignIn.sharedInstance.signIn(withPresenting: self.getRootViewController()) { [weak self] (result, error) in
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

                let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                                 accessToken: result.user.accessToken.tokenString)

                Auth.auth().signIn(with: credential) { (authResult, error) in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        if let error = error {
                            self?.errorMessage = "Firebase Sign In failed: \(error.localizedDescription)"
                        } else {
                            self?.errorMessage = nil
                            // Token will be set by the auth state listener
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
        } catch let signOutError as NSError {
            isLoading = false
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