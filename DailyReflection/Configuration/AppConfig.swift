// Config.swift
// AppConfig.swift
import Foundation

struct AppConfig {
    // Claude API 配置
    static let claudeAPIKey: String = {
        // 1. 从环境变量读取
        if let envKey = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"] {
            return envKey
        }
        
        // 2. 从Info.plist读取
        if let plistKey = Bundle.main.object(forInfoDictionaryKey: "CLAUDE_API_KEY") as? String {
            return plistKey
        }
        
        #if DEBUG
        print("⚠️ 警告：未找到 CLAUDE_API_KEY，使用测试模式")
        return "test_key_debug_mode"
        #else
        fatalError("请在Info.plist中配置CLAUDE_API_KEY")
        #endif
    }()
    
    // API 基础 URL
    static let claudeAPIBaseURL = "https://api.anthropic.com/v1/"
    
    // App Group 标识（与项目设置一致）
    static let appGroupIdentifier = "group.com.yourapp.dailyreflection"
    
    // 获取共享的 UserDefaults
    static var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupIdentifier)
    }
    
    // MARK: - 网络请求辅助
    
    static func createClaudeRequest(endpoint: String, method: String = "POST") -> URLRequest? {
        guard let url = URL(string: claudeAPIBaseURL + endpoint) else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(claudeAPIKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        return request
    }
    
    static func createMessageRequest(prompt: String, model: String = "claude-3-5-sonnet-20241022") -> URLRequest? {
        var request = createClaudeRequest(endpoint: "messages")
        
        let requestBody: [String: Any] = [
            "model": model,
            "max_tokens": 1000,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]
        
        do {
            request?.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("❌ 创建请求体失败: \(error)")
            return nil
        }
        
        return request
    }
    
    // MARK: - 功能开关
    
    static var enableHybridFoodRecognition: Bool {
        return true  // 启用混合智能识别
    }
    
    static var enableFoodCache: Bool {
        return true  // 启用食物缓存
    }
    
    static var aiCostPerCall: Double {
        return 0.001  // 每次AI调用估算成本（美元）
    }
}
