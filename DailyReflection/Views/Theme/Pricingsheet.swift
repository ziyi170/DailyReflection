//
//  Pricingsheet .swift
//  DailyReflection
//
//  Created by 小艺 on 2026/2/15.
//
import SwiftUI
import StoreKit


// MARK: - PricingSheet（四档完整订阅页）
// 触发场景：aiLimit / whiteNoise / task / themes / manual

enum PricingTrigger {
    case aiLimit        // AI 次数用完
    case whiteNoise     // 点击白噪音
    case task           // 任务超限
    case themes         // 主题锁定
    case lifetimeUpsell // 买单品后弹出买断特价
    case manual         // 用户主动打开
}

struct PricingSheet: View {
    let trigger: PricingTrigger
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = StoreKitManager.shared
    @ObservedObject private var sub = SubscriptionManager.shared
    @State private var selectedPlan: SelectedPlan = .basicYearly
    @State private var isAnimating = false
    @State private var showLifetimeSection = false

    enum SelectedPlan: String, CaseIterable {
        case basicMonthly  = "基础月订"
        case basicYearly   = "基础年订"
        case proMonthly    = "Pro月订"
        case proYearly     = "Pro年订"

        var productId: String {
            switch self {
            case .basicMonthly:  return ProductID.basicMonthly
            case .basicYearly:   return ProductID.basicYearly
            case .proMonthly:    return ProductID.proMonthly
            case .proYearly:     return ProductID.proYearly
            }
        }

        var isYearly: Bool { self == .basicYearly || self == .proYearly }
        var isPro: Bool    { self == .proMonthly  || self == .proYearly }
    }

    // 根据触发场景选默认方案
    init(trigger: PricingTrigger) {
        self.trigger = trigger
        _selectedPlan = State(initialValue: trigger == .themes ? .proYearly : .basicYearly)
    }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // ── Hero ────────────────────────────────
                    heroSection
                        .padding(.top, 8)

                    // ── 触发场景说明 ──────────────────────
                    if trigger != .manual && trigger != .lifetimeUpsell {
                        triggerBanner
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                    }

                    // ── 权益对比（三列）────────────────────
                    featureComparisonSection
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                    // ── 方案选择器 ───────────────────────
                    planSelectorSection
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                    // ── 首周免费 badge ───────────────────
                    if selectedPlan.isYearly {
                        freeTrialBadge
                            .padding(.top, 12)
                    }

                    // ── 订阅按钮 ─────────────────────────
                    subscribeButton
                        .padding(.horizontal, 20)
                        .padding(.top, 14)

                    // ── 分割线 ───────────────────────────
                    divider
                        .padding(.top, 20)

                    // ── ¥198 买断区块 ────────────────────
                    lifetimeSection
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    // ── 订阅条款（审核必须）──────────────
                    termsSection
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    // ── 底部链接 ─────────────────────────
                    bottomLinks
                        .padding(.top, 12)
                        .padding(.bottom, 40)
                }
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.secondary)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) { isAnimating = true }
        }
    }

    // MARK: - Hero
    private var heroSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: selectedPlan.isPro
                            ? [Color.purple.opacity(0.18), Color.blue.opacity(0.12)]
                            : [Color.blue.opacity(0.15), Color.cyan.opacity(0.1)],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 88, height: 88)
                Text(selectedPlan.isPro ? "👑" : "⭐")
                    .font(.system(size: 42))
            }
            .scaleEffect(isAnimating ? 1 : 0.6)
            .opacity(isAnimating ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.65), value: isAnimating)

            Text(heroTitle)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(selectedPlan.isPro
                    ? LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
                    : LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing))
                .multilineTextAlignment(.center)

            Text(heroSubtitle)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .opacity(isAnimating ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.78).delay(0.05), value: isAnimating)
    }

    private var heroTitle: String {
        switch trigger {
        case .aiLimit:      return "AI 次数已用完"
        case .whiteNoise:   return "解锁全部白噪音"
        case .task:         return "解锁无限任务"
        case .themes:       return "解锁全部主题"
        case .lifetimeUpsell: return "🎁 专属特价"
        case .manual:       return selectedPlan.isPro ? "升级 Pro 会员" : "解锁基础版"
        }
    }

    private var heroSubtitle: String {
        switch trigger {
        case .aiLimit:    return "升级 Pro，每天 5 次 AI 日记分析"
        case .whiteNoise: return "基础版即可享受全部白噪音，无限畅听"
        case .task:       return "基础版解锁无限任务，告别限制"
        case .themes:     return "Pro 会员解锁全部主题 + 动态背景"
        case .lifetimeUpsell: return "再加 ¥X，永久拥有全部皮肤"
        case .manual:     return "选择适合你的方案"
        }
    }

    // MARK: - Trigger Banner
    private var triggerBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: triggerIcon)
                .font(.system(size: 18))
                .foregroundColor(triggerColor)
                .frame(width: 32)

            Text(triggerDescription)
                .font(.system(size: 13))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(triggerColor.opacity(0.08))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(triggerColor.opacity(0.2), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var triggerIcon: String {
        switch trigger {
        case .aiLimit:    return "sparkles"
        case .whiteNoise: return "music.note"
        case .task:       return "checklist"
        case .themes:     return "paintpalette.fill"
        default:          return "star.fill"
        }
    }

    private var triggerColor: Color {
        switch trigger {
        case .aiLimit:    return .purple
        case .whiteNoise: return .blue
        case .task:       return .green
        case .themes:     return .orange
        default:          return .blue
        }
    }

    private var triggerDescription: String {
        switch trigger {
        case .aiLimit:    return "今日 AI 分析次数已用完。Pro 会员每天 5 次，还有周报、月报功能。"
        case .whiteNoise: return "白噪音功能需要基础版或以上权限。¥6/月，白噪音 + 无限任务全拿下。"
        case .task:       return "免费版最多创建 3 个任务。基础版解锁无限任务，轻松管理你的每一天。"
        case .themes:     return "这个主题是 Pro 专属。升级 Pro 即可解锁全部主题、头像框和动态背景。"
        default:          return ""
        }
    }

    // MARK: - Feature Comparison（三列：免费 / 基础 / Pro）
    private var featureComparisonSection: some View {
        VStack(spacing: 0) {
            // Header row
            HStack(spacing: 0) {
                Text("功能")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ForEach(["免费", "基础", "Pro"], id: \.self) { col in
                    Text(col)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(col == "Pro" ? .purple : col == "基础" ? .blue : .secondary)
                        .frame(width: 52, alignment: .center)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.bottom, 2)

            // Feature rows
            ForEach(featureRows, id: \.title) { row in
                FeatureRow(row: row)
            }
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var featureRows: [FeatureRowData] {[
        FeatureRowData(title: "白噪音",      free: "×",      basic: "全部",  pro: "全部"),
        FeatureRowData(title: "任务管理",    free: "3个",    basic: "无限",  pro: "无限"),
        FeatureRowData(title: "AI 日记分析", free: "体验1次", basic: "×",    pro: "5次/天"),
        FeatureRowData(title: "AI 周报/月报",free: "×",      basic: "×",    pro: "✓"),
        FeatureRowData(title: "主题皮肤",    free: "1个",    basic: "1个",   pro: "全部"),
        FeatureRowData(title: "动态背景",    free: "2种",    basic: "2种",   pro: "7种"),
        FeatureRowData(title: "头像框",      free: "基础",   basic: "基础",  pro: "全部"),
        FeatureRowData(title: "数据统计",    free: "7天",    basic: "全部",  pro: "全部"),
        FeatureRowData(title: "iCloud 同步", free: "×",      basic: "✓",    pro: "✓"),
        FeatureRowData(title: "家庭共享",    free: "×",      basic: "×",    pro: "✓"),
    ]}

    // MARK: - Plan Selector（2×2 网格）
    private var planSelectorSection: some View {
        VStack(spacing: 10) {
            // 基础版行
            HStack(spacing: 10) {
                PlanCard(
                    planName: "基础", price: "月订", period: store.displayPrice(for: ProductID.basicMonthly),
                    badge: nil, isSelected: selectedPlan == .basicMonthly, accentColor: .blue
                ) { selectedPlan = .basicMonthly }

                PlanCard(
                    planName: "基础", price: "年订", period: store.displayPrice(for: ProductID.basicYearly),
                    badge: "省30%", isSelected: selectedPlan == .basicYearly, accentColor: .blue
                ) { selectedPlan = .basicYearly }
            }

            // Pro 行
            HStack(spacing: 10) {
                PlanCard(
                    planName: "Pro", price: "月订", period: store.displayPrice(for: ProductID.proMonthly),
                    badge: nil, isSelected: selectedPlan == .proMonthly, accentColor: .purple
                ) { selectedPlan = .proMonthly }

                PlanCard(
                    planName: "Pro", price: "年订", period: store.displayPrice(for: ProductID.proYearly),
                    badge: "省32%", isSelected: selectedPlan == .proYearly, accentColor: .purple
                ) { selectedPlan = .proYearly }
            }
        }
    }

    // MARK: - Free Trial Badge
    private var freeTrialBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "gift.fill")
                .font(.system(size: 13))
                .foregroundColor(.green)
            Text("首周免费体验，随时可取消")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.green)
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .background(Color.green.opacity(0.1))
        .clipShape(Capsule())
    }

    // MARK: - Subscribe Button
    private var subscribeButton: some View {
        Button {
            Task { await store.purchaseSubscription(selectedPlan.productId) }
        } label: {
            HStack(spacing: 10) {
                if store.isLoading {
                    ProgressView().tint(.white).scaleEffect(0.85)
                } else {
                    Image(systemName: selectedPlan.isPro ? "crown.fill" : "star.fill")
                }
                VStack(spacing: 1) {
                    Text(store.isLoading ? "处理中…" : subscribeButtonTitle)
                        .font(.system(size: 17, weight: .bold))
                    if selectedPlan.isYearly {
                        Text("首周免费 · 随时取消")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: selectedPlan.isPro ? [.purple, .blue] : [.blue, .cyan],
                    startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: (selectedPlan.isPro ? Color.purple : Color.blue).opacity(0.35),
                    radius: 12, y: 6)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(store.isLoading)
    }

    private var subscribeButtonTitle: String {
        selectedPlan.isYearly ? "开始免费试用" : "立即订阅"
    }

    // MARK: - Divider
    private var divider: some View {
        HStack {
            Rectangle().fill(Color(UIColor.separator)).frame(height: 0.5)
            Text("或").font(.system(size: 12)).foregroundColor(.secondary).padding(.horizontal, 12)
            Rectangle().fill(Color(UIColor.separator)).frame(height: 0.5)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Lifetime Section（¥198 买断）
    private var lifetimeSection: some View {
        Button {
            Task { await store.purchaseLifetime() }
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(colors: [.orange.opacity(0.15), .yellow.opacity(0.1)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 48, height: 48)
                    Text("♾️").font(.system(size: 22))
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text("永久买断")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.primary)
                        Text("一次付清")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 7).padding(.vertical, 2)
                            .background(Color.orange.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    Text("全部皮肤 + 基础版权益（白噪音·任务）永久有效")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(store.displayPrice(for: ProductID.lifetimeSkins))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                    Text("买断")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.orange.opacity(0.3), lineWidth: 1.5))
            .shadow(color: .orange.opacity(0.12), radius: 8, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Terms（审核必须）
    private var termsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("订阅说明")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
            Text("""
• 年订含7天免费试用，试用期内取消不扣费
• 月订 ¥6（基础）/ ¥12（Pro），年订 ¥68（基础）/ ¥98（Pro）
• 到期前 24 小时自动续期，可随时在 App Store 取消
• 买断 ¥198，一次付清永久有效，不含 AI 功能
""")
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(Color(UIColor.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var bottomLinks: some View {
        VStack(spacing: 8) {
            Button { Task { await StoreKitManager.shared.restorePurchases() } } label: {
                Text("恢复购买")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            HStack(spacing: 16) {
                Link("隐私政策", destination: URL(string: "https://yourapp.com/privacy")!)
                    .font(.system(size: 12)).foregroundColor(.secondary)
                Text("·").foregroundColor(.secondary)
                Link("服务条款", destination: URL(string: "https://yourapp.com/terms")!)
                    .font(.system(size: 12)).foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Supporting Views

struct FeatureRowData {
    let title: String
    let free: String
    let basic: String
    let pro: String
}

struct FeatureRow: View {
    let row: FeatureRowData

    private func cell(_ text: String, isHighlight: Bool = false) -> some View {
        Text(text)
            .font(.system(size: 12, weight: isHighlight ? .semibold : .regular))
            .foregroundColor(text == "×" ? .secondary.opacity(0.5) : (isHighlight ? .primary : .primary))
            .frame(width: 52, alignment: .center)
    }

    var body: some View {
        HStack(spacing: 0) {
            Text(row.title)
                .font(.system(size: 13))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            cell(row.free)
            cell(row.basic, isHighlight: row.basic != "×" && row.basic != row.free)
            cell(row.pro, isHighlight: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        Divider().padding(.leading, 16)
    }
}