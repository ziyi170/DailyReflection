import Foundation
import AuthenticationServices
import Combine

class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var userID: String?
    @Published var userEmail: String?
    @Published var userName: String?
    
    static let shared = AuthenticationManager()
    
    private init() {
        loadUserData()
    }
    
    func signInWithApple(completion: @escaping (Result<String, Error>) -> Void) {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        // Note: 需要在SwiftUI View中处理delegate
        // 这里只是数据模型
    }
    
    func saveUserData(userID: String, email: String?, name: String?) {
        self.userID = userID
        self.userEmail = email
        self.userName = name
        self.isAuthenticated = true
        
        UserDefaults.standard.set(userID, forKey: "appleUserID")
        UserDefaults.standard.set(email, forKey: "userEmail")
        UserDefaults.standard.set(name, forKey: "userName")
        UserDefaults.standard.set(true, forKey: "isAuthenticated")
    }
    
    func loadUserData() {
        if let userID = UserDefaults.standard.string(forKey: "appleUserID") {
            self.userID = userID
            self.userEmail = UserDefaults.standard.string(forKey: "userEmail")
            self.userName = UserDefaults.standard.string(forKey: "userName")
            self.isAuthenticated = UserDefaults.standard.bool(forKey: "isAuthenticated")
        }
    }
    
    func signOut() {
        userID = nil
        userEmail = nil
        userName = nil
        isAuthenticated = false
        
        UserDefaults.standard.removeObject(forKey: "appleUserID")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.set(false, forKey: "isAuthenticated")
    }
}

