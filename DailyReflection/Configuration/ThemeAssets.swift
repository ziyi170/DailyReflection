import SwiftUI

// MARK: - Theme Assets Manager
struct ThemeAssets {
    static let shared = ThemeAssets()
    
    // MARK: - Theme Colors
    struct Colors {
        // 默认主题
        static let defaultPrimary = Color.blue
        static let defaultSecondary = Color.blue.opacity(0.3)
        
        // 森林绿
        static let forestPrimary = Color.green
        static let forestSecondary = Color.green.opacity(0.3)
        
        // 海洋蓝
        static let oceanPrimary = Color(red: 0, green: 0.5, blue: 0.8)
        static let oceanSecondary = Color(red: 0, green: 0.5, blue: 0.8).opacity(0.3)
        
        // 樱花粉
        static let sakuraPrimary = Color(red: 1, green: 0.7, blue: 0.8)
        static let sakuraSecondary = Color(red: 1, green: 0.7, blue: 0.8).opacity(0.3)
        
        // 商务灰
        static let businessPrimary = Color.gray
        static let businessSecondary = Color.gray.opacity(0.3)
        
        // 日落橙
        static let sunsetPrimary = Color.orange
        static let sunsetSecondary = Color.orange.opacity(0.3)
        
        // 薰衣草
        static let lavenderPrimary = Color.purple
        static let lavenderSecondary = Color.purple.opacity(0.3)
        
        // 午夜黑
        static let midnightPrimary = Color(red: 0.1, green: 0.1, blue: 0.15)
        static let midnightSecondary = Color(red: 0.2, green: 0.2, blue: 0.25)
        
        // Pro 渐变色
        static let proGradient = LinearGradient(
            colors: [.purple, .blue],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        // Pro 背景色
        static let proBackgroundGradient = LinearGradient(
            colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Icons
    struct Icons {
        // 主题相关
        static let theme = "paintpalette.fill"
        static let locked = "lock.fill"
        static let unlocked = "lock.open.fill"
        static let selected = "checkmark.circle.fill"
        
        // Pro 相关
        static let crown = "crown.fill"
        static let star = "star.fill"
        static let sparkles = "sparkles"
        
        // 商城相关
        static let cart = "cart.fill"
        static let purchase = "purchased.circle.fill"
        static let gift = "gift.fill"
        
        // 通用
        static let close = "xmark.circle.fill"
        static let info = "info.circle.fill"
        static let share = "square.and.arrow.up"
        static let settings = "gear"
    }
    
    // MARK: - Sizes
    struct Sizes {
        static let cardHeight: CGFloat = 120
        static let cornerRadius: CGFloat = 16
        static let cardCornerRadius: CGFloat = 12
        static let borderWidth: CGFloat = 2
        static let selectedBorderWidth: CGFloat = 2
        static let normalBorderWidth: CGFloat = 1
        
        static let iconSize: CGFloat = 40
        static let lockIconSize: CGFloat = 30
        static let crownIconSize: CGFloat = 24
        
        static let padding: CGFloat = 16
        static let cardPadding: CGFloat = 12
        static let spacing: CGFloat = 20
    }
    
    // MARK: - Animations
    struct Animations {
        static let springResponse: Double = 0.3
        static let springDamping: Double = 0.7
        static let easeInOut: Animation = .easeInOut(duration: 0.2)
    }
    
    // MARK: - Shadows
    struct Shadows {
        static func selectedShadow(color: Color) -> some View {
            EmptyView()
                .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        
        static let cardShadow = Color.black.opacity(0.1)
        static let cardShadowRadius: CGFloat = 4
    }
}

// MARK: - Theme Preview Assets
extension ThemeAssets {
    struct PreviewPatterns {
        static func gridPattern(color: Color) -> some View {
            GeometryReader { geometry in
                Path { path in
                    let spacing: CGFloat = 20
                    let width = geometry.size.width
                    let height = geometry.size.height
                    
                    // 垂直线
                    stride(from: 0, through: width, by: spacing).forEach { x in
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: height))
                    }
                    
                    // 水平线
                    stride(from: 0, through: height, by: spacing).forEach { y in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                    }
                }
                .stroke(color.opacity(0.2), lineWidth: 1)
            }
        }
        
        static func circlePattern(color: Color) -> some View {
            GeometryReader { geometry in
                ForEach(0..<3) { row in
                    ForEach(0..<3) { col in
                        Circle()
                            .fill(color.opacity(0.3))
                            .frame(width: 20, height: 20)
                            .position(
                                x: CGFloat(col) * geometry.size.width / 2,
                                y: CGFloat(row) * geometry.size.height / 2
                            )
                    }
                }
            }
        }
        
        static func wavePattern(color: Color) -> some View {
            GeometryReader { geometry in
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let midHeight = height / 2
                    
                    path.move(to: CGPoint(x: 0, y: midHeight))
                    
                    for x in stride(from: 0, through: width, by: 1) {
                        let relativeX = x / width
                        let sine = sin(relativeX * .pi * 4)
                        let y = midHeight + sine * 20
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                .stroke(color.opacity(0.3), lineWidth: 2)
            }
        }
    }
}

// MARK: - Image Assets (if using custom images)
extension ThemeAssets {
    struct Images {
        // 如果您有自定义图片资源，在这里定义
        // static let themePlaceholder = "theme_placeholder"
        // static let proBackground = "pro_background"
        
        // SF Symbols 的替代方案
        static func systemImage(_ name: String) -> Image {
            Image(systemName: name)
        }
    }
}

// MARK: - Typography
extension ThemeAssets {
    struct Typography {
        static let title: Font = .title
        static let titleBold: Font = .title.bold()
        static let headline: Font = .headline
        static let subheadline: Font = .subheadline
        static let body: Font = .body
        static let caption: Font = .caption
        
        static func custom(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
            .system(size: size, weight: weight)
        }
    }
}

// MARK: - Localization Keys
extension ThemeAssets {
    struct Strings {
        // 主题商城
        static let themeStore = "主题商城"
        static let personalizeExperience = "个性化你的时间管理体验"
        
        // 主题名称
        static let defaultTheme = "默认"
        static let forest = "森林绿"
        static let ocean = "海洋蓝"
        static let sakura = "樱花粉"
        static let business = "商务灰"
        static let sunset = "日落橙"
        static let lavender = "薰衣草"
        static let midnight = "午夜黑"
        
        // 价格和状态
        static let free = "免费"
        static let proExclusive = "Pro专属"
        static let purchased = "已购买"
        
        // Pro 套餐
        static let proBundle = "Pro主题包"
        static let unlockAllThemes = "解锁全部主题 + AI功能"
        static let subscribeNow = "立即订阅"
        static let perYear = "/ 年"
        
        // 说明
        static let proUnlocksAll = "• Pro会员解锁所有主题"
        static let permanentPurchase = "• 单独购买永久有效"
        static let familySharing = "• 支持家庭共享"
    }
}

// MARK: - Theme Configuration
extension ThemeAssets {
    struct ThemeConfig {
        let id: String
        let name: String
        let primaryColor: Color
        let secondaryColor: Color
        let accentColor: Color?
        let icon: String?
        let preview: AnyView?
        
        init(
            id: String,
            name: String,
            primaryColor: Color,
            secondaryColor: Color,
            accentColor: Color? = nil,
            icon: String? = nil,
            preview: AnyView? = nil
        ) {
            self.id = id
            self.name = name
            self.primaryColor = primaryColor
            self.secondaryColor = secondaryColor
            self.accentColor = accentColor
            self.icon = icon
            self.preview = preview
        }
    }
    
    static func getThemeConfig(for id: String) -> ThemeConfig? {
        switch id {
        case "default":
            return ThemeConfig(
                id: "default",
                name: Strings.defaultTheme,
                primaryColor: Colors.defaultPrimary,
                secondaryColor: Colors.defaultSecondary
            )
        case "forest":
            return ThemeConfig(
                id: "forest",
                name: Strings.forest,
                primaryColor: Colors.forestPrimary,
                secondaryColor: Colors.forestSecondary,
                icon: "leaf.fill"
            )
        case "ocean":
            return ThemeConfig(
                id: "ocean",
                name: Strings.ocean,
                primaryColor: Colors.oceanPrimary,
                secondaryColor: Colors.oceanSecondary,
                icon: "water.waves"
            )
        case "sakura":
            return ThemeConfig(
                id: "sakura",
                name: Strings.sakura,
                primaryColor: Colors.sakuraPrimary,
                secondaryColor: Colors.sakuraSecondary,
                icon: "sparkles"
            )
        case "business":
            return ThemeConfig(
                id: "business",
                name: Strings.business,
                primaryColor: Colors.businessPrimary,
                secondaryColor: Colors.businessSecondary,
                icon: "briefcase.fill"
            )
        case "sunset":
            return ThemeConfig(
                id: "sunset",
                name: Strings.sunset,
                primaryColor: Colors.sunsetPrimary,
                secondaryColor: Colors.sunsetSecondary,
                icon: "sunset.fill"
            )
        case "lavender":
            return ThemeConfig(
                id: "lavender",
                name: Strings.lavender,
                primaryColor: Colors.lavenderPrimary,
                secondaryColor: Colors.lavenderSecondary,
                icon: "cloud.fill"
            )
        case "midnight":
            return ThemeConfig(
                id: "midnight",
                name: Strings.midnight,
                primaryColor: Colors.midnightPrimary,
                secondaryColor: Colors.midnightSecondary,
                icon: "moon.stars.fill"
            )
        default:
            return nil
        }
    }
}

// MARK: - Color Extensions
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
