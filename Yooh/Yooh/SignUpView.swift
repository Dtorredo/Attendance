import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var role = "student"
    private let roles = ["student", "lecturer"]

    @FocusState private var focusedField: Field?

    enum Field {
        case firstName, lastName, email, password
    }

    private var isFormValid: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty
    }

    var body: some View {
        ZStack {
            // Background to match LoginView
            LinearGradient(colors: [Color(.systemIndigo), Color(.systemBlue)],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            // Floating card
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 6) {
                        Text("Create Account")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("Join Yooh")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    // Name fields
                    HStack(spacing: 12) {
                        VStack {
                            HStack {
                                Image(systemName: "person")
                                    .foregroundColor(.secondary)
                                TextField("First Name", text: $firstName)
                                    .autocapitalization(.words)
                                    .focused($focusedField, equals: .firstName)
                            }
                            .padding(10)
                            .background(Color(.systemBackground).opacity(0.6))
                            .cornerRadius(10)
                        }

                        VStack {
                            HStack {
                                Image(systemName: "person")
                                    .foregroundColor(.secondary)
                                TextField("Last Name", text: $lastName)
                                    .autocapitalization(.words)
                                    .focused($focusedField, equals: .lastName)
                            }
                            .padding(10)
                            .background(Color(.systemBackground).opacity(0.6))
                            .cornerRadius(10)
                        }
                    }

                    // Email (using your email.png asset)
                    HStack {
                        Image("email")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 18, height: 18)
                            .foregroundColor(.secondary) // only applies if asset is template
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .focused($focusedField, equals: .email)
                    }
                    .padding(12)
                    .background(Color(.systemBackground).opacity(0.6))
                    .cornerRadius(12)

                    // Password + toggle
                    HStack {
                        Image(systemName: "lock")
                            .foregroundColor(.secondary)
                        if showPassword {
                            TextField("Password", text: $password)
                                .textContentType(.newPassword)
                                .focused($focusedField, equals: .password)
                        } else {
                            SecureField("Password", text: $password)
                                .textContentType(.newPassword)
                                .focused($focusedField, equals: .password)
                        }

                        Button {
                            withAnimation { showPassword.toggle() }
                        } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12)
                    .background(Color(.systemBackground).opacity(0.6))
                    .cornerRadius(12)

                    // Role picker
                    Picker("Role", selection: $role) {
                        ForEach(roles, id: \.self) { r in
                            Text(r.capitalized).tag(r)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.top, 6)

                    // Error message
                    if let error = authManager.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }

                    // Primary Sign Up Button
                    Button(action: {
                        print("🔥 Sign Up button tapped!")
                        print("📧 Email: \(email)")
                        print("👤 Name: \(firstName) \(lastName)")
                        print("🎭 Role: \(role)")
                        print("✅ Form valid: \(isFormValid)")

                        if isFormValid {
                            authManager.signUp(firstName: firstName,
                                               lastName: lastName,
                                               email: email,
                                               password: password,
                                               role: role)
                        } else {
                            print("❌ Form is not valid!")
                        }
                    }) {
                        HStack {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image("email")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 20)
                            }
                            Text("Sign Up with Email")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: isFormValid ? [Color.blue, Color.indigo] : [Color.gray],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .disabled(!isFormValid || authManager.isLoading)
                    .padding(.top, 8)

                    // Divider
                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.secondary.opacity(0.3))
                        Text("or")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.secondary.opacity(0.3))
                    }
                    .padding(.vertical, 8)

                    // Google Sign Up Button
                    Button(action: {
                        print("🔥 Google Sign-Up button tapped!")
                        authManager.signInWithGoogle()
                    }) {
                        HStack {
                            Image("google_logo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                            Text("Sign Up with Google")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.systemBackground).opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(12)
                    }
                    .disabled(authManager.isLoading)

                    // Cancel / go back
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                }
                .padding(20)
                .frame(maxWidth: 380)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color(.systemBackground).opacity(0.9))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.18), radius: 20, x: 0, y: 10)
                .padding()
                .padding(.vertical, 30)
            } // ScrollView
            .sheet(isPresented: .constant(false)) { EmptyView() } // no-op to avoid nested sheet issues
        } // ZStack
        .onTapGesture { focusedField = nil }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onReceive(authManager.$token) { token in
            if token != nil {
                dismiss()
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
            .environmentObject(AuthManager())
    }
}
