import Foundation
import Combine

// MARK: - Authentication Service
class AuthenticationService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var currentStudent: Student?
    @Published var currentFaculty: Faculty?
    @Published var currentAdmin: Admin?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let baseURL = "" // TODO: Replace with actual API URL when backend is ready
    
    // MARK: - Login Methods
    func login(enrollmentNumber: String, password: String, userType: UserType) {
        isLoading = true
        errorMessage = nil
        
        let loginRequest = LoginRequest(
            enrollmentNumber: userType == .student ? enrollmentNumber : nil,
            employeeId: userType != .student ? enrollmentNumber : nil,
            password: password,
            userType: userType
        )
        
        performAPILogin(request: loginRequest)
    }
    
    // MARK: - Real API Login (Implement when backend is ready)
    private func performAPILogin(request: LoginRequest) {
        guard let url = URL(string: "\(baseURL)/auth/login") else {
            DispatchQueue.main.async {
                self.errorMessage = "Invalid API URL"
                self.isLoading = false
            }
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to encode request"
                self.isLoading = false
            }
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: urlRequest)
            .map(\.data)
            .decode(type: LoginResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    self.isLoading = false
                    if case .failure(let error) = completion {
                        self.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { response in
                    if response.success {
                        self.currentUser = response.user
                        self.currentStudent = response.student
                        self.currentFaculty = response.faculty
                        self.currentAdmin = response.admin
                        self.isAuthenticated = true
                        
                        if let token = response.token {
                            self.saveAuthToken(token)
                        }
                    } else {
                        self.errorMessage = response.message
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Logout
    func logout() {
        currentUser = nil
        currentStudent = nil
        currentFaculty = nil
        currentAdmin = nil
        isAuthenticated = false
        errorMessage = nil
        removeAuthToken()
    }
    
    // MARK: - Token Management
    private func saveAuthToken(_ token: String) {
        KeychainHelper.save(token, for: "auth_token")
    }
    
    private func getAuthToken() -> String? {
        return KeychainHelper.get(for: "auth_token")
    }
    
    private func removeAuthToken() {
        KeychainHelper.delete(for: "auth_token")
    }
    
    // MARK: - Check Authentication Status
    func checkAuthenticationStatus() {
        if let token = getAuthToken() {
            // TODO: Validate token with backend when ready
            // validateTokenWithBackend(token)
        }
    }
    
    // MARK: - Password Reset
    func resetPassword(enrollmentNumber: String, userType: UserType) {
        // TODO: Implement password reset functionality
        print("Password reset requested for: \(enrollmentNumber)")
    }
}

// MARK: - Keychain Helper
class KeychainHelper {
    static func save(_ data: String, for key: String) {
        let data = data.data(using: .utf8)!
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ] as [String: Any]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    static func get(for key: String) -> String? {
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ] as [String: Any]
        
        var dataTypeRef: AnyObject?
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == noErr {
            if let data = dataTypeRef as? Data {
                return String(data: data, encoding: .utf8)
            }
        }
        return nil
    }
    
    static func delete(for key: String) {
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ] as [String: Any]
        
        SecItemDelete(query as CFDictionary)
    }
} 