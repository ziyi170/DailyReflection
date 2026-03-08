import StoreKit
import SwiftUI
import Combine

// MARK: - StoreKitManager（四档体系完整版）
// 免费 / 基础版（¥6月/¥68年）/ Pro（¥12月/¥98年）/ 买断（¥198）

@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()

    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var showSuccessToast = false
    @Published var pendingMessage: String?          // 家长控制 pending

    private var updateListenerTask: Task<Void, Error>?

    private init() {
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await syncEntitlements()
        }
    }

    deinit { updateListenerTask?.cancel() }

    // MARK: - Load Products
    func loadProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: ProductID.all)
                .sorted { $0.price < $1.price }
        } catch {
            errorMessage = "商品加载失败，请检查网络"
            print("❌ loadProducts: \(error)")
        }
        isLoading = false
    }

    // MARK: - 购买订阅（基础版 / Pro）
    @discardableResult
    func purchaseSubscription(_ productId: String) async -> Bool {
        guard let product = product(for: productId) else {
            errorMessage = "商品不存在"
            return false
        }
        return await doPurchase(product) {
            await self.syncEntitlements()
            self.successMessage = self.successText(for: productId)
            self.showSuccessToast = true
            HapticFeedback.success()
        }
    }

    // MARK: - 购买买断（¥198）
    @discardableResult
    func purchaseLifetime() async -> Bool {
        guard let product = product(for: ProductID.lifetimeSkins) else {
            errorMessage = "买断商品不存在"
            return false
        }
        return await doPurchase(product) {
            await self.syncEntitlements()
            self.successMessage = "🎉 永久买断已激活！全部皮肤已解锁"
            self.showSuccessToast = true
            HapticFeedback.success()
        }
    }

    // MARK: - 购买单品主题（¥6）
    @discardableResult
    func purchaseSingleTheme(_ themeId: String) async -> Bool {
        guard let productId = singleThemeProductId(themeId),
              let product = product(for: productId) else {
            errorMessage = "主题商品不存在"
            return false
        }
        return await doPurchase(product) {
            SubscriptionManager.shared.unlockSingleTheme(themeId)
            self.successMessage = "主题已解锁！"
            self.showSuccessToast = true
            HapticFeedback.success()
        }
    }

    // MARK: - 恢复购买（审核必须）
    func restorePurchases() async {
        isLoading = true
        do {
            try await AppStore.sync()
            await syncEntitlements()
            successMessage = "购买已恢复"
            showSuccessToast = true
            HapticFeedback.success()
        } catch {
            if (error as? SKError)?.code != .paymentCancelled {
                errorMessage = "恢复失败，请稍后重试"
            }
        }
        isLoading = false
    }

    // MARK: - Core Purchase Logic
    private func doPurchase(_ product: Product, onSuccess: @escaping () async -> Void) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let tx):
                    await tx.finish()           // ✅ 必须先 finish
                    await onSuccess()
                    isLoading = false
                    return true
                case .unverified(_, let err):
                    errorMessage = "购买验证失败，请联系客服"
                    print("❌ unverified: \(err)")
                }
            case .userCancelled:
                break                           // 用户取消，静默处理
            case .pending:
                pendingMessage = "购买待审核（需要家长批准），完成后将自动解锁"
            @unknown default:
                errorMessage = "未知错误，请重试"
            }
        } catch {
            switch (error as? SKError)?.code {
            case .paymentCancelled:             break
            case .paymentNotAllowed:            errorMessage = "此设备不允许应用内购买"
            case .cloudServiceNetworkConnectionFailed: errorMessage = "网络连接失败，请重试"
            default:                            errorMessage = "购买失败，请稍后重试"
            }
            print("❌ purchase error: \(error)")
            HapticFeedback.error()
        }

        isLoading = false
        return false
    }

    // MARK: - Sync Entitlements（权益同步，唯一入口）
    func syncEntitlements() async {
        var highestTier: SubscriptionTier = .free
        var expDate: Date? = nil
        var renewing = false
        var purchasedThemes: Set<String> = []

        for await result in Transaction.currentEntitlements {
            guard case .verified(let tx) = result else { continue }
            guard tx.revocationDate == nil else { continue }
            if let exp = tx.expirationDate, exp < Date() { continue }

            let pid = tx.productID

            // 买断
            if pid == ProductID.lifetimeSkins {
                if .lifetime > highestTier { highestTier = .lifetime }
            }
            // Pro 订阅
            else if pid == ProductID.proYearly || pid == ProductID.proMonthly {
                if .pro > highestTier {
                    highestTier = .pro
                    expDate = tx.expirationDate
                }
            }
            // 基础版订阅
            else if pid == ProductID.basicYearly || pid == ProductID.basicMonthly {
                if .basic > highestTier {
                    highestTier = .basic
                    expDate = tx.expirationDate
                }
            }
            // 单品主题
            else if let themeId = ProductID.themeId(from: pid) {
                purchasedThemes.insert(themeId)
            }
        }

        // 查询续期状态
        if highestTier == .pro || highestTier == .basic {
            renewing = await checkRenewing(for: highestTier)
        }

        // 写入 SubscriptionManager（单一真相源）
        SubscriptionManager.shared.setTier(highestTier, expirationDate: expDate, isRenewing: renewing)
        purchasedThemes.forEach { SubscriptionManager.shared.unlockSingleTheme($0) }

        print("✅ Tier synced: \(highestTier) exp:\(String(describing: expDate))")
    }

    private func checkRenewing(for tier: SubscriptionTier) async -> Bool {
        let productId = tier == .pro ? ProductID.proYearly : ProductID.basicYearly
        guard let product = product(for: productId),
              let subInfo = product.subscription else { return false }
        let statuses = (try? await subInfo.status) ?? []
        return statuses.contains { status in
            if case .verified(let info) = status.renewalInfo { return info.willAutoRenew }
            return false
        }
    }

    // MARK: - Transaction Listener（全生命周期）
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached(priority: .background) {
            for await result in Transaction.updates {
                if case .verified(let tx) = result {
                    await self.syncEntitlements()
                    await tx.finish()
                }
            }
        }
    }

    // MARK: - Helpers
    func product(for id: String) -> Product? {
        products.first { $0.id == id }
    }

    func displayPrice(for id: String) -> String {
        product(for: id)?.displayPrice ?? "--"
    }

    private func singleThemeProductId(_ themeId: String) -> String? {
        switch themeId {
        case "forest":   return ProductID.themeForest
        case "ocean":    return ProductID.themeOcean
        case "sakura":   return ProductID.themeSakura
        case "business": return ProductID.themeBusiness
        default:         return nil
        }
    }

    private func successText(for productId: String) -> String {
        switch productId {
        case ProductID.basicMonthly:  return "✅ 基础版已激活！白噪音 + 任务已解锁"
        case ProductID.basicYearly:   return "✅ 基础版年订已激活！享受全年基础权益"
        case ProductID.proMonthly:    return "🎉 Pro 已激活！全部功能已解锁"
        case ProductID.proYearly:     return "🎉 Pro 年订已激活！AI + 全皮肤已解锁"
        default:                      return "✅ 购买成功！"
        }
    }
}

// MARK: - Haptic helper（避免重复依赖 HapticManager）
private struct HapticFeedback {
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func error()   { UINotificationFeedbackGenerator().notificationOccurred(.error) }
}