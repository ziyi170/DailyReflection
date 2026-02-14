import SwiftUI

// MARK: - Theme Configuration
struct ThemeConfiguration {
    static let shared = ThemeConfiguration()
    
    // MARK: - Pricing
    struct Pricing {
        static let singleThemePrice = 6
        static let proYearlyPrice = 98
        static let proMonthlyPrice = 12
        
        static let currencySymbol = "¥"
        
        static func formatPrice(_ price: Int) -> String {
            return "\(currencySymbol)\(price)"
        }
    }
    
    // MARK: - Theme Definitions
    static let allThemes: [AppTheme] = [
        // 免费主题
        AppTheme(
            id: "default",
            name: "默认",
            primaryColor: ThemeAssets.Colors.defaultPrimary,
            secondaryColor: ThemeAssets.Colors.defaultSecondary,
            price: nil,
            isPro: false
        ),
        
        // 付费主题
        AppTheme(
            id: "forest",
            name: "森林绿",
            primaryColor: ThemeAssets.Colors.forestPrimary,
            secondaryColor: ThemeAssets.Colors.forestSecondary,
            price: Pricing.singleThemePrice,
            isPro: false
        ),
        
        AppTheme(
            id: "ocean",
            name: "海洋蓝",
            primaryColor: ThemeAssets.Colors.oceanPrimary,
            secondaryColor: ThemeAssets.Colors.oceanSecondary,
            price: Pricing.singleThemePrice,
            isPro: false
        ),
        
        AppTheme(
            id: "sakura",
            name: "樱花粉",
            primaryColor: ThemeAssets.Colors.sakuraPrimary,
            secondaryColor: ThemeAssets.Colors.sakuraSecondary,
            price: Pricing.singleThemePrice,
            isPro: false
        ),
        
        AppTheme(
            id: "business",
            name: "商务灰",
            primaryColor: ThemeAssets.Colors.businessPrimary,
            secondaryColor: ThemeAssets.Colors.businessSecondary,
            price: Pricing.singleThemePrice,
            isPro: false
        ),
        
        // Pro 专属主题
        AppTheme(
            id: "sunset",
            name: "日落橙",
            primaryColor: ThemeAssets.Colors.sunsetPrimary,
            secondaryColor: ThemeAssets.Colors.sunsetSecondary,
            price: nil,
            isPro: true
        ),
        
        AppTheme(
            id: "lavender",
            name: "薰衣草",
            primaryColor: ThemeAssets.Colors.lavenderPrimary,
            secondaryColor: ThemeAssets.Colors.lavenderSecondary,
            price: nil,
            isPro: true
        ),
        
        AppTheme(
            id: "midnight",
            name: "午夜黑",
            primaryColor: ThemeAssets.Colors.midnightPrimary,
            secondaryColor: ThemeAssets.Colors.midnightSecondary,
            price: nil,
            isPro: true
        )
    ]
    
    // MARK: - Theme Categories
    enum ThemeCategory: String, CaseIterable {
        case free = "免费"
        case paid = "付费"
        case pro = "Pro专属"
        
        func themes() -> [AppTheme] {
            switch self {
            case .free:
                return allThemes.filter { $0.price == nil && !$0.isPro }
            case .paid:
                return allThemes.filter { $0.price != nil }
            case .pro:
                return allThemes.filter { $0.isPro }
            }
        }
    }
    
    // MARK: - Product IDs (for StoreKit)
    struct ProductIDs {
        // 单个主题
        static let forestTheme = "com.yourapp.theme.forest"
        static let oceanTheme = "com.yourapp.theme.ocean"
        static let sakuraTheme = "com.yourapp.theme.sakura"
        static let businessTheme = "com.yourapp.theme.business"
        
        // Pro 订阅
        static let proYearly = "com.yourapp.pro.yearly"
        static let proMonthly = "com.yourapp.pro.monthly"
        
        static func productID(for themeId: String) -> String? {
            switch themeId {
            case "forest": return forestTheme
            case "ocean": return oceanTheme
            case "sakura": return sakuraTheme
            case "business": return businessTheme
            default: return nil
            }
        }
    }
    
    // MARK: - UserDefaults Keys
    struct UserDefaultsKeys {
        static let selectedTheme = "selectedTheme"
        static let unlockedThemes = "unlockedThemes"
        static let isPro = "isPro"
        static let proExpirationDate = "proExpirationDate"
        static let hasSeenThemeStore = "hasSeenThemeStore"
    }
}

// MARK: - Theme Manager

    


// MARK: - Notification Names
extension Notification.Name {
    static let themeDidChange = Notification.Name("themeDidChange")
}

// MARK: - Environment Key for Theme
struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue: AppTheme = ThemeConfiguration.allThemes[0]
}

extension EnvironmentValues {
    var currentTheme: AppTheme {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}

// MARK: - View Extension for Easy Theme Access
extension View {
    func withCurrentTheme() -> some View {
        self.environment(\.currentTheme, ThemeManager.shared.currentTheme)
    }
}
