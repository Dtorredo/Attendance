import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isShowingSignUp = false
    @FocusState private var focusedField: Field?

    @EnvironmentObject var authManager: AuthManager

    enum Field {
        case email, password
    }

    private var isFormValid: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(colors: [Color(.systemIndigo), Color(.systemBlue)],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            // Decorative soft circles
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 260, height: 260)
                    .blur(radius: 30)
                    .offset(x: -120, y: -140)
                Circle()
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 200, height: 200)
                    .blur(radius: 30)
                    .offset(x: 140, y: 200)
            }

            // Floating card
            VStack(spacing: 18) {
                // Header
                VStack(spacing: 6) {
                    Text("Yooh")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Sign in to your account")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Email field
                HStack {
                    Image(systemName: "envelope")
                        .foregroundColor(.secondary)
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
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(focusedField == .email ? Color.accentColor.opacity(0.6) : Color.clear, lineWidth: 1)
                )

                // Password field with toggle
                HStack {
                    Image(systemName: "lock")
                        .foregroundColor(.secondary)
                    if showPassword {
                        TextField("Password", text: $password)
                            .textContentType(.password)
                            .focused($focusedField, equals: .password)
                    } else {
                        SecureField("Password", text: $password)
                            .textContentType(.password)
                            .focused($focusedField, equals: .password)
                    }

                    Button(action: { withAnimation { showPassword.toggle() } }) {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(Color(.systemBackground).opacity(0.6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(focusedField == .password ? Color.accentColor.opacity(0.6) : Color.clear, lineWidth: 1)
                )

                // Error message from AuthManager
                if let error = authManager.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 6)
                }

                // Login button
                Button(action: {
                    // Call your AuthManager exactly as implemented (no trailing closure)
                    authManager.login(email: email, password: password)
                }) {
                    Text("Sign In")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.accentColor : Color.gray.opacity(0.45))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(!isFormValid)

                // Sign up link
                Button(action: { isShowingSignUp.toggle() }) {
                    Text("Don't have an account? Sign Up")
                        .font(.footnote)
                        .foregroundColor(.accentColor)
                }
                .padding(.top, 6)
            }
            .padding(20)
            .frame(maxWidth: 380)
            .background(
                // Glassy card look
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(.systemBackground).opacity(0.8))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.18), radius: 20, x: 0, y: 10)
            .padding()
            .padding(.vertical, 30)
            .sheet(isPresented: $isShowingSignUp) {
                SignUpView()
                    .environmentObject(authManager)
            }
        } // ZStack
        .onTapGesture {
            focusedField = nil
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .preferredColorScheme(.dark) // remove if you want to follow system theme
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthManager())
    }
}
