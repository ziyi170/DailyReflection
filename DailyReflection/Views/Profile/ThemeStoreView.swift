import SwiftUI

struct ThemeStoreView: View {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: ThemeAssets.Sizes.spacing) {
                // 头部说明
                VStack(spacing: 8) {
                    Text(ThemeAssets.Strings.themeStore)
                        .font(ThemeAssets.Typography.titleBold)
                    
                    Text(ThemeAssets.Strings.personalizeExperience)
                        .font(ThemeAssets.Typography.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, ThemeAssets.Sizes.spacing)
                
                // Pro包推荐
                if !themeManager.isPro {
                    ProBundleCard()
                        .padding(.horizontal, ThemeAssets.Sizes.padding)
                }
                
                // 主题网格
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: ThemeAssets.Sizes.padding) {
                    ForEach(ThemeConfiguration.allThemes) { theme in
                        ThemeCard(
                            theme: theme,
                            isSelected: themeManager.currentTheme.id == theme.id,
                            isUnlocked: themeManager.isThemeUnlocked(theme),
                            onSelect: {
                                themeManager.selectTheme(theme)
                            },
                            onPurchase: {
                                purchaseTheme(theme)
                            }
                        )
                    }
                }
                .padding(.horizontal, ThemeAssets.Sizes.padding)
                
                // 说明文字
                VStack(spacing: 8) {
                    Text(ThemeAssets.Strings.proUnlocksAll)
                    Text(ThemeAssets.Strings.permanentPurchase)
                    Text(ThemeAssets.Strings.familySharing)
                }
                .font(ThemeAssets.Typography.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, ThemeAssets.Sizes.spacing)
            }
        }
        .navigationTitle(ThemeAssets.Strings.themeStore)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func purchaseTheme(_ theme: AppTheme) {
        // TODO: 实现StoreKit购买
        print("购买主题: \(theme.name)")
    }
}

struct ThemeCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let isUnlocked: Bool
    let onSelect: () -> Void
    let onPurchase: () -> Void
    
    var body: some View {
        Button(action: isUnlocked ? onSelect : onPurchase) {
            VStack(spacing: ThemeAssets.Sizes.cardPadding) {
                // 主题预览
                ZStack {
                    RoundedRectangle(cornerRadius: ThemeAssets.Sizes.cardCornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [theme.primaryColor, theme.secondaryColor],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: ThemeAssets.Sizes.cardHeight)
                    
                    if isSelected {
                        Image(systemName: ThemeAssets.Icons.selected)
                            .font(.system(size: ThemeAssets.Sizes.iconSize))
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                    }
                    
                    if !isUnlocked {
                        RoundedRectangle(cornerRadius: ThemeAssets.Sizes.cardCornerRadius)
                            .fill(Color.black.opacity(0.5))
                        
                        Image(systemName: ThemeAssets.Icons.locked)
                            .font(.system(size: ThemeAssets.Sizes.lockIconSize))
                            .foregroundColor(.white)
                    }
                }
                
                // 主题信息
                VStack(spacing: 4) {
                    Text(theme.name)
                        .font(ThemeAssets.Typography.headline)
                    
                    Text(theme.priceText)
                        .font(ThemeAssets.Typography.subheadline)
                        .foregroundColor(isUnlocked ? .green : .secondary)
                }
            }
            .padding(ThemeAssets.Sizes.padding)
            .background(Color(.systemBackground))
            .cornerRadius(ThemeAssets.Sizes.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: ThemeAssets.Sizes.cornerRadius)
                    .stroke(
                        isSelected ? theme.primaryColor : Color.gray.opacity(0.2),
                        lineWidth: isSelected ?
                            ThemeAssets.Sizes.selectedBorderWidth :
                            ThemeAssets.Sizes.normalBorderWidth
                    )
            )
            .shadow(
                color: isSelected ? theme.primaryColor.opacity(0.3) : .clear,
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(.plain)
    }
}

struct ProBundleCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: ThemeAssets.Icons.crown)
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(ThemeAssets.Strings.proBundle)
                        .font(ThemeAssets.Typography.headline)
                    Text(ThemeAssets.Strings.unlockAllThemes)
                        .font(ThemeAssets.Typography.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("¥\(ThemeConfiguration.Pricing.proYearlyPrice)")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text(ThemeAssets.Strings.perYear)
                        .font(ThemeAssets.Typography.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Button(action: {
                // TODO: 跳转到订阅页面
            }) {
                Text(ThemeAssets.Strings.subscribeNow)
                    .font(ThemeAssets.Typography.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ThemeAssets.Colors.proGradient)
                    .cornerRadius(ThemeAssets.Sizes.cardCornerRadius)
            }
        }
        .padding(ThemeAssets.Sizes.padding)
        .background(ThemeAssets.Colors.proBackgroundGradient)
        .cornerRadius(ThemeAssets.Sizes.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: ThemeAssets.Sizes.cornerRadius)
                .stroke(ThemeAssets.Colors.proGradient, lineWidth: 2)
        )
    }
}
