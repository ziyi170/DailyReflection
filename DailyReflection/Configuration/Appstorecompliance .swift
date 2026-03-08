import SwiftUI
import StoreKit

// ============================================================
// MARK: - App Store 审核完整清单 & 实现
// ============================================================
//
// ✅ = 已在代码中实现
// ⚠️ = 需要你手动配置（Xcode / App Store Connect）
// ❌ = 容易被拒绝的常见原因
//
// 【3.1.1 应用内购买 - 非消耗型 & 订阅】
// ✅ 使用 StoreKit 2 的 Transaction.currentEntitlements 恢复购买
// ✅ Transaction.updates 监听器在 App 整个生命周期运行
// ✅ 所有 unverified 交易不解锁内容
// ✅ .pending 状态单独处理（家长控制）
// ✅ transaction.finish() 在解锁内容后立即调用
// ✅ revocationDate 和 expirationDate 都有检查
// ✅ 价格使用 product.displayPrice（不写死价格）
// ⚠️ App Store Connect 需配置：订阅组、免费试用期（建议7天）
// ⚠️ 隐私政策 URL 和服务条款 URL 必须在 App Store Connect 填写
// ❌ 不能用自己的支付系统替代 IAP（会被直接拒绝）
//
// 【3.1.2 订阅】
// ✅ 订阅状态（自动续期/到期时间）在 UI 上展示
// ✅ 订阅管理入口（见下方 ManageSubscriptionButton）
// ✅ 恢复购买按钮明显可见
// ⚠️ 必须在 App 内显示订阅条款（价格、周期、取消方式）
//
// 【5.1.1 隐私 - 数据收集】
// ⚠️ Privacy Manifest (PrivacyInfo.xcprivacy) 必须包含
// ⚠️ 如果用了 UserDefaults，需要声明 NSPrivacyAccessedAPITypeReasons
//
// 【2.1 App Completeness】
// ✅ 测试账号信息在 App Store Connect Review Notes 中提供
// ⚠️ 所有 IAP 商品需要在 App Store Connect 创建并等待审核
// ============================================================


// MARK: - 1. 订阅条款视图（必须在购买前展示）
struct SubscriptionTermsView: View {
    let yearlyPrice: String
    let monthlyPrice: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("订阅说明")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)

            Text("""
• 年度订阅：\(yearlyPrice) / 年，月均不足 \(monthlyPrice)
• 订阅将在当前周期结束前 24 小时自动续期
• 可随时前往 App Store「订阅」设置中取消
• 购买即表示同意我们的隐私政策和服务条款
• 取消订阅后，当前周期内仍可使用 Pro 功能
""")
                .font(.system(size: 11))
                .foregroundColor(Color.secondary.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.tertiarySystemGroupedBackground))
        )
    }
}

// MARK: - 2. 管理订阅按钮（App Store 要求必须提供入口）
struct ManageSubscriptionButton: View {
    var body: some View {
        SubscriptionStoreView(productIDs: [
            ThemeConfiguration.ProductIDs.proYearly,
            ThemeConfiguration.ProductIDs.proMonthly
        ])
        .subscriptionStoreControlStyle(.prominentPicker)
        .subscriptionStorePickerItemBackground(.thinMaterial)
        .storeButton(.visible, for: .restorePurchases)
    }
}

// MARK: - 3. 在设置页面显示 Pro 状态（用于订阅管理）
struct ProStatusSection: View {
    @ObservedObject private var storeKit = StoreKitManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var sub = SubscriptionManager.shared
    @State private var showManageSheet = false

    var body: some View {
        if themeManager.isPro {
            VStack(spacing: 0) {
                HStack {
                    Label("Pro 会员", systemImage: "crown.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
                        )
                    Spacer()
                    Text(sub.expirationText)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding()

                Divider().padding(.horizontal)

                // ✅ 管理订阅入口
                Button {
                    showManageSheet = true
                } label: {
                    HStack {
                        Text("管理订阅")
                            .font(.system(size: 15))
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                .manageSubscriptionsSheet(isPresented: $showManageSheet)
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - 4. Rate App（请求评分 - 正确姿势）
struct ReviewRequestManager {
    private static let launchCountKey = "appLaunchCount"
    private static let lastReviewVersionKey = "lastReviewRequestVersion"

    // ✅ 只在合适时机请求（不要 App 一启动就弹）
    // 建议：用户完成某个正向操作后调用
    static func requestReviewIfAppropriate() {
        let count = UserDefaults.standard.integer(forKey: launchCountKey)
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let lastVersion = UserDefaults.standard.string(forKey: lastReviewVersionKey) ?? ""

        // 每个版本只请求一次，且用户启动超过 5 次后才请求
        guard count >= 5, currentVersion != lastVersion else { return }

        if #available(iOS 18.0, *) {
            // ✅ iOS 18+ 新 API：AppStore.requestReview(in:)
            if let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                AppStore.requestReview(in: scene)
                UserDefaults.standard.set(currentVersion, forKey: lastReviewVersionKey)
            }
        } else {
            // iOS 16 / 17 兼容
            if let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
                UserDefaults.standard.set(currentVersion, forKey: lastReviewVersionKey)
            }
        }
    }

    static func incrementLaunchCount() {
        let count = UserDefaults.standard.integer(forKey: launchCountKey)
        UserDefaults.standard.set(count + 1, forKey: launchCountKey)
    }
}

// MARK: - 5. Privacy Manifest 内容说明（PrivacyInfo.xcprivacy）
// ⚠️ 在 Xcode 中添加 PrivacyInfo.xcprivacy 文件，内容参考：
/*
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" ...>
<plist version="1.0">
<dict>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>  <!-- 存储用户偏好设置 -->
            </array>
        </dict>
    </array>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>  <!-- 如不收集数据，留空 -->
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyTracking</key>
    <false/>
</dict>
</plist>
*/

// MARK: - 6. App Store Connect 配置清单
/*
 ⚠️ 必须在 App Store Connect 完成的配置：

 【商品配置】（App > 功能 > 应用内购买）
 1. 非消耗型商品：
    - com.yourapp.theme.forest    ¥6  森林绿主题
    - com.yourapp.theme.ocean     ¥6  海洋蓝主题
    - com.yourapp.theme.sakura    ¥6  樱花粉主题
    - com.yourapp.theme.business  ¥6  商务灰主题
    （头像框商品同理）

 2. 自动续期订阅：
    - 先创建"订阅组"：Pro 功能
    - com.yourapp.pro.yearly   ¥98/年  层级1
    - com.yourapp.pro.monthly  ¥12/月  层级1
    - 建议设置 7 天免费试用

 【App 信息】
 - 隐私政策 URL（必须）
 - 版权信息
 - 年龄分级：4+（如有反思日记涉及心理，考虑设 12+）

 【审核备注（Review Notes）】
 - 提供测试账号（如功能需要登录）
 - 说明 IAP 测试：使用 Sandbox 账户 xxx@example.com / 密码 xxx
 - 说明 Pro 功能入口位置
 - 如果 API Key 需要特殊配置，在这里说明

 【截图要求】
 - iPhone 6.7"（必须）
 - iPhone 6.5"（必须）
 - iPad Pro 12.9"（如支持 iPad）
 - 每个截图尺寸最多 10 张，建议包含：
   主页、主题商城、Pro升级页、个人页头像框
*/

// MARK: - 7. 常见被拒原因预防
/*
 ❌ 2.1 崩溃 / 明显 Bug
   → 在真机上完整测试购买流程（包括 Sandbox 环境）
   → 测试网络断开时的表现
   → 测试 .pending 状态（家长控制）

 ❌ 3.1.1 绕过 IAP
   → 不能有任何引导用户到 Web 购买 Pro 的链接
   → 不能在 App 内展示其他 App 的购买链接

 ❌ 3.1.2 订阅未清晰说明
   → SubscriptionTermsView 必须在购买按钮附近展示
   → 必须有"恢复购买"按钮
   → 必须有"管理订阅"入口

 ❌ 5.1.1 隐私
   → 必须有 PrivacyInfo.xcprivacy
   → 如果用了 UserDefaults，必须声明 reason

 ❌ 4.0 设计
   → 不能有仅在 App 内存在的占位图、Lorem Ipsum
   → 头像框选择器必须有真实预览

 ❌ 1.5 Developer Info
   → App Store 页面的支持链接必须能打开（不能是死链）
   → 隐私政策链接必须能打开
*/

// MARK: - 8. Sandbox 测试指南（写在这里方便团队参考）
/*
 测试 IAP 流程：

 1. 在 Xcode > Product > Scheme > Edit Scheme > Run > Options
    勾选 "StoreKit Configuration" 选择你的 .storekit 配置文件

 2. 创建 Sandbox 测试账号：
    App Store Connect > 用户和访问 > 沙盒 > 测试员

 3. 在真机上测试：
    设置 > App Store > 沙盒账户（登录测试账号）

 4. 订阅加速比例（Sandbox 环境）：
    1周  → 3分钟
    1个月 → 5分钟
    1年  → 1小时

 5. 测试场景清单：
    □ 首次购买主题
    □ 购买 Pro 年度
    □ 购买 Pro 月度
    □ 恢复购买（换设备）
    □ 订阅过期降级
    □ 网络中断购买
    □ 家长控制 pending 状态
    □ 退款后权益撤销（通过 App Store Connect 模拟退款）
*/
//
//  Appstorecompliance.swift
//  DailyReflection
//
//  Created by 小艺 on 2026/2/15.
//