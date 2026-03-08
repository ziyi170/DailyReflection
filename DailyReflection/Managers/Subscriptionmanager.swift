import SwiftUI
import StoreKit

// MARK: - SubscriptionPlan
// 订阅层级定义，所有权益判断的唯一来源

enum SubscriptionTier: Int, Comparable {
    case free    = 0
    case basic   = 1   // 基础版：白噪音 + 任务 + 1次AI体验
    case pro     = 2   // Pro：全功能 + AI每日5次
    case lifetime = 3  // 买断：皮肤全解锁 + 基础版权益（无AI上限外功能）

    static func < (lhs: SubscriptionTier, rhs: SubscriptionTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - All Product IDs（唯一入口，统一管理）
struct ProductID {
    // ── 基础版订阅 ──────────────────────────
    static let basicMonthly   = "com.yourapp.basic.monthly"    // ¥6/月
    static let basicYearly    = "com.yourapp.basic.yearly"     // ¥68/年（首周免费）

    // ── Pro 订阅 ────────────────────────────
    static let proMonthly     = "com.yourapp.pro.monthly"      // ¥12/月
    static let proYearly      = "com.yourapp.pro.yearly"       // ¥98/年（首周免费）

    // ── 买断 ────────────────────────────────
    static let lifetimeSkins  = "com.yourapp.lifetime.skins"   // ¥198 买断皮肤+基础权益

    // ── 单品皮肤（非消耗型）────────────────
    static let themeForest    = "com.yourapp.theme.forest"
    static let themeOcean     = "com.yourapp.theme.ocean"
    static let themeSakura    = "com.yourapp.theme.sakura"
    static let themeBusiness  = "com.yourapp.theme.business"

    // ── 便捷集合 ─────────────────────────────
    static let allSubscriptions: Set<String> = [
        basicMonthly, basicYearly, proMonthly, proYearly
    ]
    static let allSingleThemes: [String] = [
        themeForest, themeOcean, themeSakura, themeBusiness
    ]
    static var all: Set<String> {
        var s = allSubscriptions
        s.insert(lifetimeSkins)
        allSingleThemes.forEach { s.insert($0) }
        return s
    }

    static func themeId(from productId: String) -> String? {
        switch productId {
        case themeForest:   return "forest"
        case themeOcean:    return "ocean"
        case themeSakura:   return "sakura"
        case themeBusiness: return "business"
        default:            return nil
        }
    }
}

// MARK: - Entitlement（每层权益定义）
struct Entitlement {
    let tier: SubscriptionTier

    // 白噪音
    var whiteNoiseUnlimited: Bool { tier >= .basic }

    // 任务
    var tasksUnlimited: Bool      { tier >= .basic }
    var maxFreeTasks: Int          { tier < .basic ? 3 : Int.max }

    // AI 日记分析（Haiku）
    var aiDailyLimit: Int {
        switch tier {
        case .free:     return 0          // 无AI（用首次体验钩子单独给）
        case .basic:    return 0          // 基础版无常规AI（有1次体验入口）
        case .pro:      return 5          // Pro每日5次
        case .lifetime: return 0          // 买断无AI（只有皮肤+基础权益）
        }
    }

    // 皮肤 / 主题
    var allThemesUnlocked: Bool  { tier == .pro || tier == .lifetime }
    var allFramesUnlocked: Bool  { tier == .pro || tier == .lifetime }
    var allBgUnlocked: Bool      { tier == .pro || tier == .lifetime }

    // Pro 专属动态框 & 背景
    var proAnimatedFrames: Bool  { tier == .pro }
    var proAnimatedBg: Bool      { tier == .pro }

    // 数据统计
    var fullStats: Bool          { tier >= .basic }

    // iCloud
    var cloudSync: Bool          { tier >= .basic }

    // 高级 AI 功能（周报/月报）
    var aiWeeklyReport: Bool     { tier == .pro }
    var aiMonthlyReport: Bool    { tier == .pro }
}

// MARK: - SubscriptionManager（权威状态源）
@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published private(set) var currentTier: SubscriptionTier = .free
    @Published private(set) var expirationDate: Date?
    @Published private(set) var isRenewing: Bool = false
    @Published private(set) var hasUsedBasicAITrial: Bool = false  // 免费用户的1次AI体验

    // 派生：当前权益
    var entitlement: Entitlement { Entitlement(tier: currentTier) }

    // 基础版 AI 体验次数（每次装机只有1次）
    private let basicTrialKey = "hasUsedBasicAITrial_v1"

    private init() {
        hasUsedBasicAITrial = UserDefaults.standard.bool(forKey: basicTrialKey)
        // 真实 tier 由 StoreKitManager 在 updatePurchasedProducts 后调用 setTier 写入
        loadCachedTier()
    }

    // MARK: - Tier 更新（只由 StoreKitManager 调用）
    func setTier(_ tier: SubscriptionTier, expirationDate: Date? = nil, isRenewing: Bool = false) {
        currentTier = tier
        self.expirationDate = expirationDate
        self.isRenewing = isRenewing
        cacheTier(tier)
    }

    // MARK: - AI 使用量（Pro 每日5次，跨日重置）
    private var aiUsageKey: String {
        let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
        return "aiDailyUsage_\(dateStr)"
    }

    var aiUsedToday: Int {
        UserDefaults.standard.integer(forKey: aiUsageKey)
    }

    var canUseAI: Bool {
        if currentTier == .pro { return aiUsedToday < 5 }
        // 基础版 & 免费用户：只有体验入口，不走这个通道
        return false
    }

    var aiRemainingToday: Int {
        max(0, entitlement.aiDailyLimit - aiUsedToday)
    }

    func recordAIUsage() {
        let used = UserDefaults.standard.integer(forKey: aiUsageKey)
        UserDefaults.standard.set(used + 1, forKey: aiUsageKey)
    }

    // MARK: - 基础版 AI 体验（1次，永久性）
    var canUseBasicAITrial: Bool {
        !hasUsedBasicAITrial  // 无论什么 tier，只要没用过就可以体验
    }

    func consumeBasicAITrial() {
        hasUsedBasicAITrial = true
        UserDefaults.standard.set(true, forKey: basicTrialKey)
    }

    // MARK: - 任务限额
    var canAddTask: Bool {
        entitlement.tasksUnlimited
    }

    // MARK: - 皮肤权益
    func isThemeUnlocked(_ themeId: String) -> Bool {
        if entitlement.allThemesUnlocked { return true }
        // 单独买断的主题
        return purchasedSingleThemes.contains(themeId)
    }

    @Published private(set) var purchasedSingleThemes: Set<String> = []

    func unlockSingleTheme(_ themeId: String) {
        purchasedSingleThemes.insert(themeId)
        var saved = UserDefaults.standard.stringArray(forKey: "purchasedSingleThemes") ?? []
        saved.append(themeId)
        UserDefaults.standard.set(saved, forKey: "purchasedSingleThemes")
    }

    func loadPurchasedSingleThemes() {
        let saved = UserDefaults.standard.stringArray(forKey: "purchasedSingleThemes") ?? []
        purchasedSingleThemes = Set(saved)
    }

    // MARK: - 展示用文字
    var tierDisplayName: String {
        switch currentTier {
        case .free:     return "免费版"
        case .basic:    return "基础版"
        case .pro:      return "Pro 版"
        case .lifetime: return "永久买断"
        }
    }

    var tierBadgeColor: Color {
        switch currentTier {
        case .free:     return .secondary
        case .basic:    return .blue
        case .pro:      return .purple
        case .lifetime: return .orange
        }
    }

    var expirationText: String {
        guard let exp = expirationDate else { return "" }
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.locale = Locale(identifier: "zh_CN")
        let dateStr = fmt.string(from: exp)
        return isRenewing ? "续期于 \(dateStr)" : "到期于 \(dateStr)"
    }

    // MARK: - 持久化 tier（防止冷启动闪烁）
    private func cacheTier(_ tier: SubscriptionTier) {
        UserDefaults.standard.set(tier.rawValue, forKey: "cachedSubscriptionTier")
    }

    private func loadCachedTier() {
        let raw = UserDefaults.standard.integer(forKey: "cachedSubscriptionTier")
        currentTier = SubscriptionTier(rawValue: raw) ?? .free
    }
}