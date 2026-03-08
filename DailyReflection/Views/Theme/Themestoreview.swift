import SwiftUI
import StoreKit
import Combine

// MARK: - Main Theme Store View
struct ThemeStoreView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var storeKit = StoreKitManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategory: ThemeCategory = .all
    @State private var showingProSheet = false
    @State private var selectedTheme: AppTheme? = nil
    @State private var showingPurchaseAlert = false
    @State private var purchaseAlertTheme: AppTheme? = nil
    @State private var isAnimating = false
    @State private var headerOffset: CGFloat = 0
    
    enum ThemeCategory: String, CaseIterable {
        case all = "全部"
        case free = "免费"
        case paid = "付费"
        case pro = "Pro专属"
    }
    
    var filteredThemes: [AppTheme] {
        switch selectedCategory {
        case .all:
            return ThemeConfiguration.allThemes
        case .free:
            return ThemeConfiguration.allThemes.filter { $0.price == nil && !$0.isPro }
        case .paid:
            return ThemeConfiguration.allThemes.filter { $0.price != nil }
        case .pro:
            return ThemeConfiguration.allThemes.filter { $0.isPro }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // Background
                backgroundLayer
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Header spacer
                        Color.clear.frame(height: 20)
                        
                        // Pro Banner (if not pro)
                        if !themeManager.isPro {
                            proBannerSection
                                .padding(.horizontal, 20)
                                .padding(.bottom, 24)
                        }
                        
                        // Current Theme Preview
                        currentThemeSection
                            .padding(.horizontal, 20)
                            .padding(.bottom, 28)
                        
                        // Category Filter
                        categoryFilterSection
                            .padding(.bottom, 20)
                        
                        // Theme Grid
                        themeGridSection
                            .padding(.horizontal, 20)
                        
                        // Bottom padding
                        Color.clear.frame(height: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    toolbarLeadingItem
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    toolbarTrailingItem
                }
            }
        }
        .sheet(isPresented: $showingProSheet) {
            ProUpgradeSheet()
        }
        .alert("购买主题", isPresented: $showingPurchaseAlert) {
            purchaseAlertButtons
        } message: {
            if let theme = purchaseAlertTheme {
                Text("购买「\(theme.name)」主题？\n价格：¥\(theme.price ?? 0)")
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isAnimating = true
            }
        }
    }
    
    // MARK: - Background
    @ViewBuilder
    private var backgroundLayer: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            // Subtle gradient overlay
            LinearGradient(
                colors: [
                    themeManager.currentTheme.primaryColor.opacity(0.08),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Toolbar Items
    private var toolbarLeadingItem: some View {
        Text("主题商城")
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    colors: [themeManager.currentTheme.primaryColor, themeManager.currentTheme.primaryColor.opacity(0.6)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }
    
    private var toolbarTrailingItem: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.hierarchical)
        }
    }
    
    // MARK: - Pro Banner
    private var proBannerSection: some View {
        Button {
            showingProSheet = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "crown.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("解锁 Pro 专属主题")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text("+ AI 功能加持  ¥98/年")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.9), Color.blue.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: Color.purple.opacity(0.35), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(ScaleButtonStyle())
        .scaleEffect(isAnimating ? 1 : 0.95)
        .opacity(isAnimating ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: isAnimating)
    }
    
    // MARK: - Current Theme Section
    private var currentThemeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("当前使用", systemImage: "checkmark.seal.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            CurrentThemePreviewCard(theme: themeManager.currentTheme)
        }
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15), value: isAnimating)
    }
    
    // MARK: - Category Filter
    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Color.clear.frame(width: 10)
                
                ForEach(ThemeCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        title: category.rawValue,
                        isSelected: selectedCategory == category,
                        accentColor: themeManager.currentTheme.primaryColor
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            selectedCategory = category
                        }
                    }
                }
                
                Color.clear.frame(width: 10)
            }
        }
        .opacity(isAnimating ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: isAnimating)
    }
    
    // MARK: - Theme Grid
    private var themeGridSection: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 14),
                GridItem(.flexible(), spacing: 14)
            ],
            spacing: 14
        ) {
            ForEach(Array(filteredThemes.enumerated()), id: \.element.id) { index, theme in
                ThemeCard(
                    theme: theme,
                    isCurrentTheme: themeManager.currentTheme.id == theme.id,
                    isUnlocked: themeManager.isThemeUnlocked(theme),
                    accentColor: themeManager.currentTheme.primaryColor
                ) {
                    handleThemeSelection(theme)
                }
                .scaleEffect(isAnimating ? 1 : 0.9)
                .opacity(isAnimating ? 1 : 0)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.8)
                    .delay(0.25 + Double(index) * 0.05),
                    value: isAnimating
                )
            }
        }
    }
    
    // MARK: - Purchase Alert Buttons
    @ViewBuilder
    private var purchaseAlertButtons: some View {
        Button("取消", role: .cancel) {}
        Button("购买") {
            if let theme = purchaseAlertTheme {
                _Concurrency.Task {
                    await storeKit.purchaseSingleTheme(theme.id)
                }
            }
        }
    }
    
    // MARK: - Theme Selection Handler
    private func handleThemeSelection(_ theme: AppTheme) {
        HapticManager.impact(.medium)
        
        if themeManager.isThemeUnlocked(theme) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                themeManager.selectTheme(theme)
            }
        } else if theme.isPro {
            showingProSheet = true
        } else if theme.price != nil {
            purchaseAlertTheme = theme
            showingPurchaseAlert = true
        }
    }
}

// MARK: - Current Theme Preview Card
struct CurrentThemePreviewCard: View {
    let theme: AppTheme
    
    var body: some View {
        HStack(spacing: 16) {
            // Color preview
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [theme.primaryColor, theme.primaryColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                
                Image(systemName: themeIconName(theme.id))
                    .font(.system(size: 22))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(theme.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(theme.primaryColor)
                        .frame(width: 8, height: 8)
                    Circle()
                        .fill(theme.secondaryColor)
                        .frame(width: 8, height: 8)
                    
                    Text(theme.isPro ? "Pro专属" : (theme.price != nil ? "已购买" : "免费"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Label("使用中", systemImage: "checkmark.circle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(theme.primaryColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(theme.primaryColor.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: theme.primaryColor.opacity(0.15), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.primaryColor.opacity(0.2), lineWidth: 1.5)
        )
    }
    
    private func themeIconName(_ id: String) -> String {
        switch id {
        case "forest": return "leaf.fill"
        case "ocean": return "water.waves"
        case "sakura": return "sparkles"
        case "business": return "briefcase.fill"
        case "sunset": return "sunset.fill"
        case "lavender": return "cloud.fill"
        case "midnight": return "moon.stars.fill"
        default: return "paintpalette.fill"
        }
    }
}

// MARK: - Theme Card
struct ThemeCard: View {
    let theme: AppTheme
    let isCurrentTheme: Bool
    let isUnlocked: Bool
    let accentColor: Color
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                // Preview Background
                themePreviewBackground
                    .frame(height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // Overlay gradient
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.5)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // Bottom info
                VStack(alignment: .leading, spacing: 3) {
                    Text(theme.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    
                    badgeView
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                
                // Top-right badge
                VStack {
                    HStack {
                        Spacer()
                        if isCurrentTheme {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 3)
                        } else if !isUnlocked {
                            lockBadge
                        }
                    }
                    Spacer()
                }
                .padding(10)
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isCurrentTheme ? theme.primaryColor : Color.clear,
                    lineWidth: 2.5
                )
        )
        .shadow(
            color: isCurrentTheme ? theme.primaryColor.opacity(0.35) : Color.black.opacity(0.1),
            radius: isCurrentTheme ? 10 : 4,
            x: 0, y: 3
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isCurrentTheme)
    }
    
    @ViewBuilder
    private var themePreviewBackground: some View {
        ZStack {
            // Primary gradient
            LinearGradient(
                colors: [
                    theme.primaryColor,
                    theme.primaryColor.opacity(0.7),
                    theme.secondaryColor.opacity(0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Pattern overlay
            patternOverlay
                .opacity(0.15)
        }
    }
    
    @ViewBuilder
    private var patternOverlay: some View {
        GeometryReader { geo in
            Path { path in
                let spacing: CGFloat = 16
                stride(from: 0, through: geo.size.width * 2, by: spacing).forEach { x in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x - geo.size.height, y: geo.size.height))
                }
            }
            .stroke(Color.white, lineWidth: 1)
        }
    }
    
    @ViewBuilder
    private var lockBadge: some View {
        if theme.isPro {
            Image(systemName: "crown.fill")
                .font(.system(size: 16))
                .foregroundColor(.yellow)
                .padding(6)
                .background(Color.black.opacity(0.4))
                .clipShape(Circle())
        } else {
            Image(systemName: "lock.fill")
                .font(.system(size: 14))
                .foregroundColor(.white)
                .padding(6)
                .background(Color.black.opacity(0.4))
                .clipShape(Circle())
        }
    }
    
    @ViewBuilder
    private var badgeView: some View {
        if isCurrentTheme {
            EmptyView()
        } else if theme.isPro {
            Text("Pro 专属")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.yellow)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.black.opacity(0.4))
                .clipShape(Capsule())
        } else if let price = theme.price {
            Text("¥\(price)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.black.opacity(0.4))
                .clipShape(Capsule())
        } else {
            Text("免费")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white.opacity(0.85))
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.25))
                .clipShape(Capsule())
        }
    }
}

// MARK: - Category Chip
struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? accentColor : Color(UIColor.secondarySystemGroupedBackground))
                )
                .shadow(
                    color: isSelected ? accentColor.opacity(0.3) : Color.clear,
                    radius: 6, x: 0, y: 3
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Pro Upgrade Sheet
struct ProUpgradeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var storeKit = StoreKitManager.shared
    @State private var selectedPlan: PlanType = .yearly
    @State private var isLoading = false
    @State private var isAnimating = false
    
    enum PlanType: String {
        case yearly = "yearly"
        case monthly = "monthly"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.15),
                        Color.blue.opacity(0.1),
                        Color(UIColor.systemGroupedBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // Hero Section
                        heroSection
                        
                        // Feature List
                        featureListSection
                        
                        // Plan Selector
                        planSelectorSection
                        
                        // Purchase Button
                        purchaseButton
                        
                        // Fine Print
                        finePrintSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.secondary)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isAnimating = true
            }
        }
    }
    
    // MARK: - Hero
    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.2), Color.blue.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
                    )
            }
            .scaleEffect(isAnimating ? 1 : 0.5)
            .opacity(isAnimating ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.65), value: isAnimating)
            
            VStack(spacing: 8) {
                Text("升级 Pro 会员")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("解锁全部主题 + AI 智能功能")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : 15)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: isAnimating)
        }
    }
    
    // MARK: - Features
    private var featureListSection: some View {
        VStack(spacing: 12) {
            ForEach(Array(proFeatures.enumerated()), id: \.offset) { index, feature in
                ProFeatureRow(icon: feature.0, title: feature.1, desc: feature.2)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(x: isAnimating ? 0 : -20)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.8).delay(0.15 + Double(index) * 0.06),
                        value: isAnimating
                    )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    private var proFeatures: [(String, String, String)] {
        [
            ("paintpalette.fill", "全部主题无限使用", "8套精美主题任意切换"),
            ("sparkles", "AI 智能日记分析", "Claude AI 深度洞察每日记录"),
            ("chart.line.uptrend.xyaxis", "高级数据统计", "周期报告与趋势分析"),
            ("icloud.fill", "多端云同步", "iPhone、iPad 无缝同步"),
            ("person.2.fill", "家庭共享", "最多6位家庭成员共享"),
        ]
    }
    
    // MARK: - Plan Selector
    private var planSelectorSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Yearly plan
                PlanCard(
                    planName: "年度订阅",
                    price: "¥98",
                    period: "/ 年",
                    badge: "省58%",
                    isSelected: selectedPlan == .yearly,
                    accentColor: .purple
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selectedPlan = .yearly
                    }
                }
                
                // Monthly plan
                PlanCard(
                    planName: "月度订阅",
                    price: "¥12",
                    period: "/ 月",
                    badge: nil,
                    isSelected: selectedPlan == .monthly,
                    accentColor: .blue
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selectedPlan = .monthly
                    }
                }
            }
        }
        .opacity(isAnimating ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.45), value: isAnimating)
    }
    
    // MARK: - Purchase Button
    private var purchaseButton: some View {
        Button {
            _Concurrency.Task {
                isLoading = true
                let productId = selectedPlan == .yearly
                    ? ThemeConfiguration.ProductIDs.proYearly
                    : ThemeConfiguration.ProductIDs.proMonthly
                await storeKit.purchaseSubscription(productId)
                isLoading = false
            }
        } label: {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.85)
                } else {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 16))
                }
                Text(isLoading ? "处理中..." : "立即订阅")
                    .font(.system(size: 17, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [.purple, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .purple.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isLoading)
        .opacity(isAnimating ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.5), value: isAnimating)
    }
    
    // MARK: - Fine Print
    private var finePrintSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                Button("恢复购买") {
                    _Concurrency.Task { await storeKit.restorePurchases() }
                }
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                
                Text("·")
                    .foregroundColor(.secondary)
                
                Link("隐私政策", destination: URL(string: "https://yourapp.com/privacy")!)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Text("·")
                    .foregroundColor(.secondary)
                
                Link("服务条款", destination: URL(string: "https://yourapp.com/terms")!)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Text("订阅自动续期，可随时在 App Store 设置中取消")
                .font(.system(size: 11))
                .foregroundColor(Color.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .opacity(isAnimating ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.55), value: isAnimating)
    }
}

// MARK: - Pro Feature Row
struct ProFeatureRow: View {
    let icon: String
    let title: String
    let desc: String
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.15), Color.blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 38, height: 38)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(
                        LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(
                    LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
        }
    }
}

// MARK: - Plan Card
struct PlanCard: View {
    let planName: String
    let price: String
    let period: String
    let badge: String?
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 8) {
                    Text(planName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isSelected ? accentColor : .secondary)
                    
                    VStack(spacing: 2) {
                        Text(price)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(isSelected ? accentColor : .primary)
                        
                        Text(period)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    isSelected ? accentColor : Color.clear,
                                    lineWidth: 2
                                )
                        )
                )
                .shadow(
                    color: isSelected ? accentColor.opacity(0.25) : Color.clear,
                    radius: 8, x: 0, y: 4
                )
                
                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing))
                        )
                        .offset(x: -8, y: -8)
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

// MARK: - Haptic Manager
struct HapticManager {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}

// MARK: - Preview
struct ThemeStoreView_Previews: PreviewProvider {
    static var previews: some View {
        ThemeStoreView()
    }
}



//
//  Themestoreview.swift
//  DailyReflection
//
//  Created by 小艺 on 2026/2/15.
//