import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppTheme
    @Published var unlockedThemes: Set<String>
    @Published var isPro: Bool
    
    private init() {
        // 加载当前主题
        let savedThemeId = UserDefaults.standard.string(
            forKey: ThemeConfiguration.UserDefaultsKeys.selectedTheme
        ) ?? "default"
        
        self.currentTheme = ThemeConfiguration.allThemes.first { $0.id == savedThemeId }
            ?? ThemeConfiguration.allThemes[0]
        
        // 加载已解锁主题
        let savedUnlocked = UserDefaults.standard.stringArray(
            forKey: ThemeConfiguration.UserDefaultsKeys.unlockedThemes
        ) ?? ["default"]
        self.unlockedThemes = Set(savedUnlocked)
        
        // 加载 Pro 状态
        self.isPro = UserDefaults.standard.bool(
            forKey: ThemeConfiguration.UserDefaultsKeys.isPro
        )
    }
    
    // MARK: - Public Methods
    func selectTheme(_ theme: AppTheme) {
        guard isThemeUnlocked(theme) else { return }
        
        currentTheme = theme
        UserDefaults.standard.set(
            theme.id,
            forKey: ThemeConfiguration.UserDefaultsKeys.selectedTheme
        )
        
        NotificationCenter.default.post(
            name: .themeDidChange,
            object: theme
        )
    }
    
    func unlockTheme(_ themeId: String) {
        unlockedThemes.insert(themeId)
        saveUnlockedThemes()
    }
    
    func isThemeUnlocked(_ theme: AppTheme) -> Bool {
        if theme.price == nil && !theme.isPro {
            return true
        }
        if isPro {
            return true
        }
        return unlockedThemes.contains(theme.id)
    }
    
    func activatePro() {
        isPro = true
        UserDefaults.standard.set(
            true,
            forKey: ThemeConfiguration.UserDefaultsKeys.isPro
        )
        
        ThemeConfiguration.allThemes.filter { $0.isPro }.forEach { theme in
            unlockedThemes.insert(theme.id)
        }
        saveUnlockedThemes()
    }
    
    func deactivatePro() {
        isPro = false
        UserDefaults.standard.set(
            false,
            forKey: ThemeConfiguration.UserDefaultsKeys.isPro
        )
    }
    
    private func saveUnlockedThemes() {
        UserDefaults.standard.set(
            Array(unlockedThemes),
            forKey: ThemeConfiguration.UserDefaultsKeys.unlockedThemes
        )
    }
}


