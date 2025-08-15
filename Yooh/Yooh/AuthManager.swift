
import Foundation
import Combine

class AuthManager: ObservableObject {
    @Published var token: String? {
        didSet {
            UserDefaults.standard.set(token, forKey: "authToken")
        }
    }
    @Published var userId: Int? {
        didSet {
            UserDefaults.standard.set(userId, forKey: "userId")
        }
    }
    @Published var errorMessage: String?

    init() {
        self.token = UserDefaults.standard.string(forKey: "authToken")
        self.userId = UserDefaults.standard.object(forKey: "userId") as? Int
    }

    func login(email: String, password: String) {
        guard let url = URL(string: "http://192.168.100.49:5001/api/auth/login") else {
            DispatchQueue.main.async {
                self.errorMessage = "Invalid URL"
            }
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = ["email": email, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Login failed: \(error.localizedDescription)"
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    self?.errorMessage = "Invalid credentials or server error."
                    return
                }

                guard let data = data else {
                    self?.errorMessage = "No data received."
                    return
                }

                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let token = json["token"] as? String {
                        self?.token = token
                        self?.decodeToken(token: token)
                        self?.errorMessage = nil
                    } else {
                        self?.errorMessage = "Invalid response format."
                    }
                } catch {
                    self?.errorMessage = "Failed to parse response."
                }
            }
        }.resume()
    }
    
    func signUp(firstName: String, lastName: String, email: String, password: String, role: String) {
        guard let url = URL(string: "http://192.168.100.49:5001/api/auth/register") else {
            DispatchQueue.main.async {
                self.errorMessage = "Invalid URL"
            }
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "firstName": firstName,
            "lastName": lastName,
            "email": email,
            "password": password,
            "role": role
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Sign up failed: \(error.localizedDescription)"
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
                    if let data = data, let responseBody = String(data: data, encoding: .utf8) {
                        self?.errorMessage = "Sign up failed: \(responseBody)"
                    } else {
                        self?.errorMessage = "Sign up failed with status code: \(String(describing: (response as? HTTPURLResponse)?.statusCode))"
                    }
                    return
                }
                
                // On successful registration, we can clear the error message
                // and the view will be dismissed. The user can then log in.
                self?.errorMessage = nil
                
                // Optionally, you could automatically log the user in here by calling the login function
                // or by parsing the response if the backend returns a token on registration.
                // For now, we'll just let the user log in manually.
            }
        }.resume()
    }

    func logout() {
        self.token = nil
        self.userId = nil
    }

    private func decodeToken(token: String) {
        let segments = token.components(separatedBy: ".")
        guard segments.count > 1 else { return }
        let payloadSegment = segments[1]

        var base64String = payloadSegment
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let requiredLength = Int(ceil(Double(base64String.count) / 4.0)) * 4
        while base64String.count < requiredLength {
            base64String += "="
        }

        guard let payloadData = Data(base64Encoded: base64String) else {
            return
        }

        do {
            if let json = try JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any],
               let user = json["user"] as? [String: Any],
               let id = user["id"] as? Int {
                self.userId = id
            }
        } catch {
            print("Failed to decode token payload: \(error)")
        }
    }
}
