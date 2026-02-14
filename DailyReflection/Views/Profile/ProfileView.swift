import SwiftUI
import AuthenticationServices

struct ProfileView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var isPro = false
    
    var body: some View {
        NavigationView {
            List {
                // 用户信息区域
                Section {
                    if authManager.isAuthenticated {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(authManager.userName ?? "用户")
                                    .font(.headline)
                                Text(authManager.userEmail ?? "")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        
                        Button("退出登录") {
                            authManager.signOut()
                        }
                        .foregroundColor(.red)
                    } else {
                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { result in
                            handleSignInWithApple(result)
                        }
                        .frame(height: 50)
                        .cornerRadius(8)
                    }
                }
                
                // 订阅状态卡片
                Section {
                    NavigationLink(destination: SubscriptionView()) {
                        HStack {
                            Image(systemName: isPro ? "crown.fill" : "crown")
                                .foregroundColor(isPro ? .yellow : .gray)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(isPro ? "Pro会员" : "免费版")
                                    .font(.headline)
                                Text(isPro ? "感谢您的支持" : "升级解锁全部功能")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // 个性化
                Section(header: Text("个性化")) {
                    NavigationLink(destination: ThemeStoreView()) {
                        Label("主题商城", systemImage: "paintbrush.fill")
                    }
                    
                    NavigationLink(destination: Text("设置页面")) {
                        Label("外观设置", systemImage: "moon.fill")
                    }
                }
                
                // 功能
                Section(header: Text("功能")) {
                    NavigationLink(destination: Text("数据管理")) {
                        Label("数据备份", systemImage: "icloud.fill")
                    }
                    
                    NavigationLink(destination: Text("通知设置")) {
                        Label("通知设置", systemImage: "bell.fill")
                    }
                }
                
                // ✅ 高级功能（新增）
                Section("高级功能") {
                    NavigationLink(destination: SystemSyncSettingsView()) {
                        Label("系统同步", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
                
                // 关于
                Section(header: Text("关于")) {
                    NavigationLink(destination: Text("使用帮助")) {
                        Label("使用帮助", systemImage: "questionmark.circle")
                    }
                    
                    NavigationLink(destination: Text("关于我们")) {
                        Label("关于我们", systemImage: "info.circle")
                    }
                    
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("我的")
        }
    }
    
    func handleSignInWithApple(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userID = appleIDCredential.user
                let email = appleIDCredential.email
                let fullName = appleIDCredential.fullName
                let name = [fullName?.givenName, fullName?.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                
                authManager.saveUserData(
                    userID: userID,
                    email: email,
                    name: name.isEmpty ? nil : name
                )
            }
        case .failure(let error):
            print("Sign in with Apple failed: \(error.localizedDescription)")
        }
    }
}
