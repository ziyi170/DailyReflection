import SwiftUI
import Combine

// MARK: - UpsellManager（特价弹窗触发逻辑）
// 原则：在用户完成正向行为后触发，不打扰，不强制

class UpsellManager: ObservableObject {
    static let shared = UpsellManager()

    @Published var currentUpsell: UpsellEvent? = nil

    // 记录触发历史，避免重复打扰
    private var shownEvents: Set<String> = {
        Set(UserDefaults.standard.stringArray(forKey: "shownUpsellEvents") ?? [])
    }()

    private init() {}

    // MARK: - 触发点（在业务代码里调用）

    /// 用户买了第2个单品主题时 → 提示买断 ¥198
    func onPurchasedSecondSingleTheme() {
        trigger(.lifetimeDeal, key: "lifetimeDeal_v1")
    }

    /// 用户使用完免费AI体验后 → 提示升级Pro
    func onUsedAITrial() {
        trigger(.aiTrialEnded, key: "aiTrialEnded_v1")
    }

    /// 连续记录7天后 → 提示基础版
    func onStreakMilestone(_ days: Int) {
        guard days == 7 || days == 14 || days == 30 else { return }
        trigger(.streakMilestone(days), key: "streak_\(days)_v1")
    }

    /// 白噪音被点击但无权限时 → 立即触发（不需要延迟）
    func onWhiteNoiseLocked() {
        // 这个不做冷却，直接触发，因为是明确的功能阻断
        currentUpsell = .whiteNoiseLocked
    }

    /// 任务超限时 → 立即触发
    func onTaskLimitReached() {
        currentUpsell = .taskLimitReached
    }

    func dismiss() {
        currentUpsell = nil
    }

    private func trigger(_ event: UpsellEvent, key: String) {
        guard !shownEvents.contains(key) else { return }
        shownEvents.insert(key)
        UserDefaults.standard.set(Array(shownEvents), forKey: "shownUpsellEvents")

        // 延迟0.5秒，等待当前操作完成动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.currentUpsell = event
        }
    }
}

// MARK: - Upsell Events
enum UpsellEvent: Identifiable {
    case lifetimeDeal           // 买单品后特价买断
    case aiTrialEnded           // AI体验用完
    case streakMilestone(Int)   // 连续打卡里程碑
    case whiteNoiseLocked       // 白噪音锁定
    case taskLimitReached       // 任务超限

    var id: String {
        switch self {
        case .lifetimeDeal:        return "lifetimeDeal"
        case .aiTrialEnded:        return "aiTrialEnded"
        case .streakMilestone(let d): return "streak_\(d)"
        case .whiteNoiseLocked:    return "whiteNoiseLocked"
        case .taskLimitReached:    return "taskLimitReached"
        }
    }
}

// MARK: - Upsell Popup View（从底部滑出的半屏弹窗）
struct UpsellPopup: View {
    let event: UpsellEvent
    @ObservedObject private var upsellManager = UpsellManager.shared
    @ObservedObject private var store = StoreKitManager.shared
    @State private var showFullPricing = false
    @State private var appeared = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // 半透明背景遮罩
            Color.black.opacity(appeared ? 0.35 : 0)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            // 弹窗主体
            VStack(spacing: 0) {
                // 拖拽指示条
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.secondary.opacity(0.35))
                    .frame(width: 36, height: 5)
                    .padding(.top, 10)
                    .padding(.bottom, 16)

                // 内容区
                content
                    .padding(.horizontal, 24)
                    .padding(.bottom, 36)
            }
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: .black.opacity(0.18), radius: 24, y: -8)
            )
            .offset(y: appeared ? 0 : 300)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                appeared = true
            }
        }
        .sheet(isPresented: $showFullPricing) {
            PricingSheet(trigger: pricingTrigger)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch event {
        case .lifetimeDeal:
            lifetimeDealContent
        case .aiTrialEnded:
            aiTrialEndedContent
        case .streakMilestone(let days):
            streakContent(days: days)
        case .whiteNoiseLocked:
            whiteNoiseLockContent
        case .taskLimitReached:
            taskLimitContent
        }
    }

    // ─── 1. 买断特价（买了单品后弹出）─────────────────────────
    private var lifetimeDealContent: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("🎁 专属特价").font(.system(size: 28))
                Text("你已购买了主题皮肤")
                    .font(.system(size: 20, weight: .bold))
                Text("再加 **¥X**，即可永久拥有**全部皮肤**")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // 价格对比
            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("继续单买")
                        .font(.system(size: 12)).foregroundColor(.secondary)
                    Text("≈ ¥24+")
                        .font(.system(size: 18, weight: .bold))
                        .strikethrough(color: .secondary)
                        .foregroundColor(.secondary)
                    Text("每个主题单独购买")
                        .font(.system(size: 10)).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                Rectangle().fill(Color(UIColor.separator)).frame(width: 1, height: 56)

                VStack(spacing: 4) {
                    Text("永久买断")
                        .font(.system(size: 12)).foregroundColor(.orange)
                    Text(store.displayPrice(for: ProductID.lifetimeSkins))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                    Text("全部皮肤 + 基础版权益")
                        .font(.system(size: 10)).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(spacing: 10) {
                // 主按钮：买断
                Button {
                    Task {
                        let ok = await store.purchaseLifetime()
                        if ok { dismiss() }
                    }
                } label: {
                    Text(store.isLoading ? "处理中…" : "♾️ 立即买断 · \(store.displayPrice(for: ProductID.lifetimeSkins))")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: .orange.opacity(0.35), radius: 10, y: 5)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(store.isLoading)

                // 次要：查看订阅
                Button { showFullPricing = true } label: {
                    Text("或查看订阅方案")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // ─── 2. AI 体验用完 ──────────────────────────────────────
    private var aiTrialEndedContent: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("✨ 感觉怎么样？")
                    .font(.system(size: 22, weight: .bold))
                Text("AI 分析帮你看见了不一样的自己")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            // 权益亮点
            VStack(spacing: 10) {
                UpsellFeatureRow(icon: "sparkles", text: "每天 5 次 AI 日记分析", highlight: true)
                UpsellFeatureRow(icon: "chart.line.uptrend.xyaxis", text: "AI 周报 + 月度情绪总结", highlight: false)
                UpsellFeatureRow(icon: "paintpalette.fill", text: "全部主题 + 动态背景解锁", highlight: false)
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(spacing: 10) {
                Button {
                    dismiss()
                    showFullPricing = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                        VStack(spacing: 1) {
                            Text("升级 Pro · 首周免费")
                                .font(.system(size: 16, weight: .bold))
                            Text("¥98/年 · 随时取消")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .purple.opacity(0.35), radius: 10, y: 5)
                }
                .buttonStyle(ScaleButtonStyle())

                Button { dismiss() } label: {
                    Text("稍后再说")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // ─── 3. 连续打卡里程碑 ───────────────────────────────────
    private func streakContent(days: Int) -> some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("🔥").font(.system(size: 52))
                Text("连续 \(days) 天！")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Text("你的坚持值得更好的体验")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            // 里程碑奖励感
            HStack(spacing: 16) {
                ForEach(["白噪音助眠", "AI 记录分析", "精美主题"], id: \.self) { item in
                    VStack(spacing: 4) {
                        Text(item == "白噪音助眠" ? "🎵" : item == "AI 记录分析" ? "✨" : "🎨")
                            .font(.system(size: 24))
                        Text(item)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(14)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(spacing: 10) {
                Button { showFullPricing = true; dismiss() } label: {
                    Text("⭐ 解锁基础版 · 首周免费")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: .blue.opacity(0.35), radius: 10, y: 5)
                }
                .buttonStyle(ScaleButtonStyle())
                Button { dismiss() } label: {
                    Text("继续免费使用")
                        .font(.system(size: 14)).foregroundColor(.secondary)
                }
            }
        }
    }

    // ─── 4. 白噪音锁定 ──────────────────────────────────────
    private var whiteNoiseLockContent: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("🎵").font(.system(size: 44))
                Text("白噪音需要基础版")
                    .font(.system(size: 20, weight: .bold))
                Text("雨声、白噪音、咖啡馆…专注时刻，从声音开始")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 12) {
                UpsellPriceBlock(label: "月订", price: store.displayPrice(for: ProductID.basicMonthly), color: .blue)
                UpsellPriceBlock(label: "年订 · 省30%", price: store.displayPrice(for: ProductID.basicYearly), color: .blue, isHighlight: true)
            }

            VStack(spacing: 10) {
                Button { showFullPricing = true; dismiss() } label: {
                    Text("⭐ 解锁白噪音 · 首周免费")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(ScaleButtonStyle())
                Button { dismiss() } label: {
                    Text("稍后再说").font(.system(size: 14)).foregroundColor(.secondary)
                }
            }
        }
    }

    // ─── 5. 任务超限 ────────────────────────────────────────
    private var taskLimitContent: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("✅").font(.system(size: 44))
                Text("任务已达上限（3个）")
                    .font(.system(size: 20, weight: .bold))
                Text("升级基础版，创建无限任务，让计划井然有序")
                    .font(.system(size: 14)).foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button { showFullPricing = true; dismiss() } label: {
                Text("⭐ 解锁无限任务 · 首周免费")
                    .font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 15)
                    .background(LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(ScaleButtonStyle())

            Button { dismiss() } label: {
                Text("稍后再说").font(.system(size: 14)).foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Helpers
    private var pricingTrigger: PricingTrigger {
        switch event {
        case .lifetimeDeal:          return .lifetimeUpsell
        case .aiTrialEnded:          return .aiLimit
        case .streakMilestone:       return .manual
        case .whiteNoiseLocked:      return .whiteNoise
        case .taskLimitReached:      return .task
        }
    }

    private func dismiss() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
            appeared = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            upsellManager.currentUpsell = nil
        }
    }
}

// MARK: - Supporting Components

struct UpsellFeatureRow: View {
    let icon: String
    let text: String
    let highlight: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(highlight ? .purple : .secondary)
                .frame(width: 22)
            Text(text)
                .font(.system(size: 14, weight: highlight ? .semibold : .regular))
                .foregroundColor(highlight ? .primary : .secondary)
            Spacer()
            if highlight {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.purple)
                    .font(.system(size: 16))
            }
        }
    }
}

struct UpsellPriceBlock: View {
    let label: String
    let price: String
    let color: Color
    var isHighlight: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(isHighlight ? color : .secondary)
            Text(price)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(isHighlight ? color : .primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHighlight ? color : Color.clear, lineWidth: 2)
        )
        .shadow(color: isHighlight ? color.opacity(0.2) : .clear, radius: 6, y: 3)
    }
}

// MARK: - Global Upsell Overlay Modifier（在 App 根视图挂载一次）
struct UpsellOverlayModifier: ViewModifier {
    @ObservedObject private var upsellManager = UpsellManager.shared

    func body(content: Content) -> some View {
        ZStack {
            content
            if let event = upsellManager.currentUpsell {
                UpsellPopup(event: event)
                    .transition(.opacity)
                    .zIndex(999)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: upsellManager.currentUpsell?.id)
    }
}

extension View {
    /// 在 App 根视图调用一次：ContentView().withUpsellOverlay()
    func withUpsellOverlay() -> some View {
        modifier(UpsellOverlayModifier())
    }
}