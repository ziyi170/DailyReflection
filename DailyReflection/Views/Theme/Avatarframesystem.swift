import SwiftUI
import Combine

// MARK: - Avatar Frame System
// 头像框系统 - 个人页面头像装饰框 + 商城集成

// MARK: - Avatar Frame Model
struct AvatarFrame: Identifiable, Equatable, Codable {
    let id: String
    let name: String
    let category: FrameCategory
    let isPro: Bool
    let price: Int?           // nil = free or pro-only
    let isAnimated: Bool

    enum FrameCategory: String, Codable, CaseIterable {
        case basic    = "基础"
        case nature   = "自然"
        case cosmic   = "宇宙"
        case festive  = "节日"
        case pro      = "Pro专属"
    }

    static func == (lhs: AvatarFrame, rhs: AvatarFrame) -> Bool { lhs.id == rhs.id }

    // Product ID for StoreKit
    var productId: String? {
        guard price != nil else { return nil }
        return "com.yourapp.avatarframe.\(id)"
    }
}

// MARK: - Frame Registry
struct AvatarFrameRegistry {
    static let allFrames: [AvatarFrame] = [
        // Basic - Free
        AvatarFrame(id: "plain",       name: "无框",    category: .basic,   isPro: false, price: nil, isAnimated: false),
        AvatarFrame(id: "circle",      name: "圆形",    category: .basic,   isPro: false, price: nil, isAnimated: false),
        AvatarFrame(id: "rounded",     name: "圆角",    category: .basic,   isPro: false, price: nil, isAnimated: false),

        // Nature - Paid ¥6
        AvatarFrame(id: "flower",      name: "花环",    category: .nature,  isPro: false, price: 6,   isAnimated: false),
        AvatarFrame(id: "leaf",        name: "绿叶",    category: .nature,  isPro: false, price: 6,   isAnimated: false),
        AvatarFrame(id: "sakura",      name: "樱花",    category: .nature,  isPro: false, price: 6,   isAnimated: false),

        // Cosmic - Paid ¥8
        AvatarFrame(id: "galaxy",      name: "星系",    category: .cosmic,  isPro: false, price: 8,   isAnimated: false),
        AvatarFrame(id: "neon",        name: "霓虹",    category: .cosmic,  isPro: false, price: 8,   isAnimated: false),

        // Pro Animated Frames
        AvatarFrame(id: "aurora_ring", name: "极光环",  category: .pro,     isPro: true,  price: nil, isAnimated: true),
        AvatarFrame(id: "fire",        name: "火焰",    category: .pro,     isPro: true,  price: nil, isAnimated: true),
        AvatarFrame(id: "sparkle",     name: "星光",    category: .pro,     isPro: true,  price: nil, isAnimated: true),
        AvatarFrame(id: "rainbow",     name: "彩虹",    category: .pro,     isPro: true,  price: nil, isAnimated: true),

        // Festive - Paid (seasonal)
        AvatarFrame(id: "newyear",     name: "新年",    category: .festive, isPro: false, price: 6,   isAnimated: false),
        AvatarFrame(id: "birthday",    name: "生日",    category: .festive, isPro: false, price: 6,   isAnimated: true),
    ]

    static var free: [AvatarFrame]    { allFrames.filter { $0.price == nil && !$0.isPro } }
    static var paid: [AvatarFrame]    { allFrames.filter { $0.price != nil } }
    static var proOnly: [AvatarFrame] { allFrames.filter { $0.isPro } }
}

// MARK: - Avatar Frame Manager
class AvatarFrameManager: ObservableObject {
    
    static let shared = AvatarFrameManager()

    @Published var currentFrameId: String {
        didSet { UserDefaults.standard.set(currentFrameId, forKey: "selectedAvatarFrame") }
    }
    @Published var unlockedFrameIds: Set<String> {
        didSet { saveUnlocked() }
    }

    var currentFrame: AvatarFrame {
        AvatarFrameRegistry.allFrames.first { $0.id == currentFrameId } ?? AvatarFrameRegistry.allFrames[0]
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "selectedAvatarFrame") ?? "circle"
        self.currentFrameId = saved

        let savedUnlocked = UserDefaults.standard.stringArray(forKey: "unlockedAvatarFrames") ?? ["plain", "circle", "rounded"]
        self.unlockedFrameIds = Set(savedUnlocked)
    }

    func isUnlocked(_ frame: AvatarFrame) -> Bool {
        if !frame.isPro && frame.price == nil { return true }
        if ThemeManager.shared.isPro { return true }
        return unlockedFrameIds.contains(frame.id)
    }

    func unlock(_ frameId: String) {
        unlockedFrameIds.insert(frameId)
    }

    func selectFrame(_ frame: AvatarFrame) {
        guard isUnlocked(frame) else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            currentFrameId = frame.id
        }
    }

    func activateProFrames() {
        AvatarFrameRegistry.proOnly.forEach { unlock($0.id) }
    }

    private func saveUnlocked() {
        UserDefaults.standard.set(Array(unlockedFrameIds), forKey: "unlockedAvatarFrames")
    }
}

// MARK: - Avatar Frame Renderer
struct AvatarView: View {
    let image: Image?
    let initials: String         // fallback 文字头像
    let size: CGFloat
    let frameId: String

    @StateObject private var frameManager = AvatarFrameManager.shared
    @StateObject private var themeManager = ThemeManager.shared

    init(image: Image? = nil, initials: String = "U", size: CGFloat = 80, frameId: String? = nil) {
        self.image = image
        self.initials = initials
        self.size = size
        self.frameId = frameId ?? AvatarFrameManager.shared.currentFrameId
    }

    var frame: AvatarFrame {
        AvatarFrameRegistry.allFrames.first { $0.id == frameId } ?? AvatarFrameRegistry.allFrames[0]
    }

    var body: some View {
        ZStack {
            // Avatar base
            avatarBase
                .frame(width: size, height: size)

            // Overlay frame decoration
            frameDecoration
        }
        .frame(width: size + frameInset, height: size + frameInset)
    }

    private var frameInset: CGFloat {
        switch frame.id {
        case "plain": return 0
        case "aurora_ring", "fire", "rainbow": return 8
        default: return 6
        }
    }

    @ViewBuilder
    private var avatarBase: some View {
        Group {
            if let img = image {
                img
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    themeManager.currentTheme.primaryColor
                    Text(String(initials.prefix(2)))
                        .font(.system(size: size * 0.35, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
        .clipShape(frameClipShape)
    }

    private var frameClipShape: AnyShape {
        switch frame.id {
        case "rounded": AnyShape(RoundedRectangle(cornerRadius: size * 0.22))
        default:        AnyShape(Circle())
        }
    }

    @ViewBuilder
    private var frameDecoration: some View {
        switch frame.id {
        case "plain":       EmptyView()
        case "circle":      circleFrame
        case "rounded":     roundedFrame
        case "flower":      flowerFrame
        case "leaf":        leafFrame
        case "sakura":      sakuraFrame
        case "galaxy":      galaxyFrame
        case "neon":        neonFrame
        case "aurora_ring": auroraRingFrame
        case "fire":        fireFrame
        case "sparkle":     sparkleFrame
        case "rainbow":     rainbowFrame
        case "newyear":     newyearFrame
        case "birthday":    birthdayFrame
        default:            circleFrame
        }
    }

    // MARK: - Frame Implementations

    private var circleFrame: some View {
        Circle()
            .stroke(themeManager.currentTheme.primaryColor, lineWidth: 3)
            .frame(width: size + 6, height: size + 6)
    }

    private var roundedFrame: some View {
        RoundedRectangle(cornerRadius: size * 0.22 + 3)
            .stroke(themeManager.currentTheme.primaryColor, lineWidth: 3)
            .frame(width: size + 6, height: size + 6)
    }

    private var flowerFrame: some View {
        ZStack {
            Circle()
                .stroke(
                    LinearGradient(colors: [.pink, .orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 3
                )
                .frame(width: size + 6, height: size + 6)

            ForEach(0..<8) { i in
                Circle()
                    .fill(Color.pink.opacity(0.6))
                    .frame(width: 10, height: 10)
                    .offset(y: -(size / 2 + CGFloat(3)))
                    .rotationEffect(.degrees(Double(i) * 45))
            }
        }
    }

    private var leafFrame: some View {
        Circle()
            .stroke(
                LinearGradient(colors: [.green, .mint, .teal], startPoint: .topLeading, endPoint: .bottomTrailing),
                lineWidth: 3
            )
            .frame(width: size + 6, height: size + 6)
            .overlay(
                ForEach(0..<6) { i in
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                        .offset(y: -(size / 2 + CGFloat(3)))
                        .rotationEffect(.degrees(Double(i) * 60))
                }
            )
    }

    private var sakuraFrame: some View {
        Circle()
            .stroke(Color.pink.opacity(0.5), lineWidth: 2.5)
            .frame(width: size + 6, height: size + 6)
            .overlay(
                ForEach(0..<5) { i in
                    Text("🌸")
                        .font(.system(size: 13))
                        .offset(y: -(size / 2 + CGFloat(3)))
                        .rotationEffect(.degrees(Double(i) * 72))
                }
            )
    }

    private var galaxyFrame: some View {
        Circle()
            .stroke(
                AngularGradient(
                    colors: [.purple, .blue, .cyan, .purple],
                    center: .center
                ),
                lineWidth: 3.5
            )
            .frame(width: size + 7, height: size + 7)
    }

    private var neonFrame: some View {
        ZStack {
            Circle()
                .stroke(Color.cyan.opacity(0.3), lineWidth: 8)
                .blur(radius: 4)
                .frame(width: size + 7, height: size + 7)
            Circle()
                .stroke(Color.cyan, lineWidth: 2)
                .frame(width: size + 7, height: size + 7)
        }
    }

    // MARK: - Animated Frames (Pro)

    private var auroraRingFrame: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSince1970
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [.purple, .blue, .cyan, .green, .purple],
                        center: .center,
                        startAngle: .degrees(t * 60),
                        endAngle: .degrees(t * 60 + 360)
                    ),
                    lineWidth: 4
                )
                .frame(width: size + 8, height: size + 8)
                .shadow(color: .purple.opacity(0.5), radius: 6)
        }
    }

    private var fireFrame: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSince1970
            ZStack {
                Circle()
                    .stroke(Color.orange.opacity(0.3), lineWidth: 10)
                    .blur(radius: 8)
                    .frame(width: size + 8, height: size + 8)
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [.yellow, .orange, .red, .orange, .yellow],
                            center: .center,
                            startAngle: .degrees(t * -80),
                            endAngle: .degrees(t * -80 + 360)
                        ),
                        lineWidth: 3.5
                    )
                    .frame(width: size + 8, height: size + 8)
            }
        }
    }

    private var sparkleFrame: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSince1970
            ZStack {
                Circle()
                    .stroke(themeManager.currentTheme.primaryColor.opacity(0.3), lineWidth: 3)
                    .frame(width: size + 8, height: size + 8)

                ForEach(0..<6) { i in
                    let angle = Double(i) * 60 + t * 40
                    let scale = (sin(t * 2 + Double(i)) + 1) / 2 * 0.6 + 0.4
                    Image(systemName: "sparkle")
                        .font(.system(size: 10))
                        .foregroundColor(themeManager.currentTheme.primaryColor)
                        .scaleEffect(scale)
                        .offset(y: -(size / 2 + CGFloat(5)))
                        .rotationEffect(.degrees(angle))
                }
            }
        }
    }

    private var rainbowFrame: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSince1970
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [.red, .orange, .yellow, .green, .blue, .purple, .red],
                        center: .center,
                        startAngle: .degrees(t * 30),
                        endAngle: .degrees(t * 30 + 360)
                    ),
                    lineWidth: 4
                )
                .frame(width: size + 8, height: size + 8)
        }
    }

    private var newyearFrame: some View {
        ZStack {
            Circle()
                .stroke(Color.red.opacity(0.8), lineWidth: 3)
                .frame(width: size + 6, height: size + 6)

            ForEach(0..<4) { i in
                Text("🧨")
                    .font(.system(size: 11))
                    .offset(y: -(size / 2 + CGFloat(3)))
                    .rotationEffect(.degrees(Double(i) * 90))
            }
        }
    }

    private var birthdayFrame: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSince1970
            ZStack {
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [.pink, .yellow, .pink],
                            center: .center,
                            startAngle: .degrees(t * 45),
                            endAngle: .degrees(t * 45 + 360)
                        ),
                        lineWidth: 3
                    )
                    .frame(width: size + 6, height: size + 6)

                ForEach(0..<5) { i in
                    let phaseShift = Double(i) * 0.8
                    let yOff = sin(t * 1.5 + phaseShift) * 4
                    Text(["🎈","🎉","🎂","✨","🎁"][i])
                        .font(.system(size: 11))
                        .offset(y: -(size / 2 + CGFloat(3)) + yOff)
                        .rotationEffect(.degrees(Double(i) * 72))
                }
            }
        }
    }
}

// MARK: - Profile Page Avatar Section (使用示例)
struct ProfileAvatarSection: View {
    @StateObject private var frameManager = AvatarFrameManager.shared
    @State private var showFramePicker = false

    var body: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                AvatarView(initials: "我", size: 88)

                // Edit button
                Button {
                    showFramePicker = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                            .frame(width: 28, height: 28)
                            .shadow(color: .black.opacity(0.15), radius: 4)
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .offset(x: 4, y: 4)
            }

            Text("点击更换头像框")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .sheet(isPresented: $showFramePicker) {
            AvatarFramePickerSheet()
        }
    }
}

// MARK: - Avatar Frame Picker Sheet
struct AvatarFramePickerSheet: View {
    @StateObject private var frameManager = AvatarFrameManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: AvatarFrame.FrameCategory? = nil
    @State private var showProUpgrade = false

    var filteredFrames: [AvatarFrame] {
        guard let cat = selectedCategory else { return AvatarFrameRegistry.allFrames }
        return AvatarFrameRegistry.allFrames.filter { $0.category == cat }
    }

    let columns = [GridItem(.adaptive(minimum: 80, maximum: 90), spacing: 16)]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Live preview
                    previewSection

                    // Category filter
                    categoryFilter

                    // Frame grid
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(filteredFrames) { frame in
                            FramePickerCell(
                                frame: frame,
                                isSelected: frameManager.currentFrameId == frame.id,
                                isUnlocked: frameManager.isUnlocked(frame)
                            ) {
                                if frameManager.isUnlocked(frame) {
                                    HapticManager.impact(.light)
                                    frameManager.selectFrame(frame)
                                } else if frame.isPro {
                                    showProUpgrade = true
                                } else {
                                    // trigger purchase
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("头像框")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeManager.currentTheme.primaryColor)
                }
            }
        }
        .sheet(isPresented: $showProUpgrade) {
            ProUpgradeSheet()
        }
    }

    private var previewSection: some View {
        VStack(spacing: 12) {
            AvatarView(initials: "我", size: 88)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: frameManager.currentFrameId)

            Text(frameManager.currentFrame.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Color.clear.frame(width: 10)

                CategoryPill(title: "全部", isSelected: selectedCategory == nil) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { selectedCategory = nil }
                }

                ForEach(AvatarFrame.FrameCategory.allCases, id: \.self) { cat in
                    CategoryPill(title: cat.rawValue, isSelected: selectedCategory == cat) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { selectedCategory = cat }
                    }
                }

                Color.clear.frame(width: 10)
            }
        }
    }
}

// MARK: - Frame Picker Cell
struct FramePickerCell: View {
    let frame: AvatarFrame
    let isSelected: Bool
    let isUnlocked: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    AvatarView(initials: "我", size: 56, frameId: frame.id)

                    if !isUnlocked {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.45))
                                .frame(width: 56, height: 56)
                            Image(systemName: frame.isPro ? "crown.fill" : "lock.fill")
                                .font(.system(size: 16))
                                .foregroundColor(frame.isPro ? .yellow : .white)
                        }
                    }

                    if isSelected {
                        Circle()
                            .stroke(Color.green, lineWidth: 2.5)
                            .frame(width: 60, height: 60)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.green)
                            .offset(x: 22, y: -22)
                    }
                }

                Text(frame.name)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .primary : .secondary)

                if let price = frame.price, !isUnlocked {
                    Text("¥\(price)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.orange)
                } else if frame.isPro && !isUnlocked {
                    Text("Pro")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Category Pill (reusable)
struct CategoryPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Capsule().fill(isSelected ? themeManager.currentTheme.primaryColor : Color(UIColor.secondarySystemGroupedBackground)))
                .shadow(color: isSelected ? themeManager.currentTheme.primaryColor.opacity(0.3) : .clear, radius: 5, y: 3)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

//
//  Avatarframesystem.swift
//  DailyReflection
//
//  Created by 小艺 on 2026/2/15.
//