import SwiftUI
import Combine
import UIKit

// MARK: - Dynamic Background System
// 动态背景系统 - 可用于个人页、首页、任意全屏视图

// MARK: - Background Style Enum
enum DynamicBackgroundStyle: String, CaseIterable, Codable {
    case none           = "none"
    case breathe        = "breathe"
    case aurora         = "aurora"
    case particles      = "particles"
    case mesh           = "mesh"
    case ripple         = "ripple"
    case constellation  = "constellation"
    case ink            = "ink"

    var displayName: String {
        switch self {
        case .none:          return "静态"
        case .breathe:       return "呼吸"
        case .aurora:        return "极光"
        case .particles:     return "粒子"
        case .mesh:          return "渐变网格"
        case .ripple:        return "水波纹"
        case .constellation: return "星座"
        case .ink:           return "水墨"
        }
    }

    var icon: String {
        switch self {
        case .none:          return "square.fill"
        case .breathe:       return "circle.dotted"
        case .aurora:        return "wand.and.stars"
        case .particles:     return "sparkles"
        case .mesh:          return "square.grid.3x3.fill"
        case .ripple:        return "water.waves"
        case .constellation: return "star.fill"
        case .ink:           return "drop.fill"
        }
    }

    var isPro: Bool {
        switch self {
        case .none, .breathe: return false
        default:              return true
        }
    }

    var price: Int? {
        switch self {
        case .none, .breathe: return nil
        default:              return nil
        }
    }
}

// MARK: - Dynamic Background View
struct DynamicBackground: View {
    let style: DynamicBackgroundStyle
    let primaryColor: Color
    let secondaryColor: Color
    var opacity: Double = 1.0

    var body: some View {
        ZStack {
            switch style {
            case .none:
                staticBackground
            case .breathe:
                BreatheBackground(primaryColor: primaryColor, secondaryColor: secondaryColor)
            case .aurora:
                AuroraBackground(primaryColor: primaryColor, secondaryColor: secondaryColor)
            case .particles:
                ParticleBackground(primaryColor: primaryColor)
            case .mesh:
                MeshGradientBackground(primaryColor: primaryColor, secondaryColor: secondaryColor)
            case .ripple:
                RippleBackground(primaryColor: primaryColor)
            case .constellation:
                ConstellationBackground(primaryColor: primaryColor)
            case .ink:
                InkBackground(primaryColor: primaryColor, secondaryColor: secondaryColor)
            }
        }
        .opacity(opacity)
        .ignoresSafeArea()
    }

    private var staticBackground: some View {
        LinearGradient(
            colors: [primaryColor.opacity(0.15), secondaryColor.opacity(0.08), Color(UIColor.systemBackground)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - 1. Breathe Background（呼吸光晕）免费
struct BreatheBackground: View {
    let primaryColor: Color
    let secondaryColor: Color

    @State private var scale1: CGFloat = 1.0
    @State private var scale2: CGFloat = 0.8
    @State private var opacity1: Double = 0.3
    @State private var opacity2: Double = 0.2

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)

            Ellipse()
                .fill(primaryColor.opacity(opacity2))
                .frame(width: 320, height: 320)
                .blur(radius: 60)
                .scaleEffect(scale2)
                .offset(x: 60, y: -80)

            Circle()
                .fill(secondaryColor.opacity(opacity1))
                .frame(width: 280, height: 280)
                .blur(radius: 50)
                .scaleEffect(scale1)
                .offset(x: -40, y: 60)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
                scale1 = 1.15
                opacity1 = 0.18
            }
            withAnimation(.easeInOut(duration: 4.2).repeatForever(autoreverses: true).delay(0.8)) {
                scale2 = 1.0
                opacity2 = 0.28
            }
        }
    }
}

// MARK: - 2. Aurora Background（极光）Pro
struct AuroraBackground: View {
    let primaryColor: Color
    let secondaryColor: Color

    var body: some View {
        auroraBody
    }

    var auroraBody: some View {
        TimelineView(.animation) { timeline in
            GeometryReader { geo in
                ZStack {
                    Color(UIColor.systemBackground)
                    auroraLayer(geo: geo, t: timeline.date.timeIntervalSince1970,
                                color: primaryColor, yBase: 0.25, amp: 60, freq: 1.2, speed: 0.4)
                    auroraLayer(geo: geo, t: timeline.date.timeIntervalSince1970,
                                color: secondaryColor, yBase: 0.35, amp: 80, freq: 0.9, speed: 0.3)
                    auroraLayer(geo: geo, t: timeline.date.timeIntervalSince1970,
                                color: primaryColor.opacity(0.5), yBase: 0.45, amp: 50, freq: 1.5, speed: 0.5)
                }
            }
        }
    }

    private func auroraLayer(
        geo: GeometryProxy,
        t: Double,
        color: Color,
        yBase: Double,
        amp: Double,
        freq: Double,
        speed: Double
    ) -> some View {
        let w: CGFloat = geo.size.width
        let h: CGFloat = geo.size.height
        let phaseOffset: Double = t * speed

        var path = Path()
        path.move(to: CGPoint(x: 0, y: h))
        for xi in stride(from: 0, through: Int(w), by: 2) {
            let x = CGFloat(xi)
            let y: CGFloat = CGFloat(Double(h) * yBase + amp * sin(Double(x) / Double(w) * .pi * freq * 2 + phaseOffset))
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine(to: CGPoint(x: w, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.closeSubpath()

        let gradient = LinearGradient(
            colors: [color.opacity(0.0), color.opacity(0.22), color.opacity(0.0)],
            startPoint: .bottom,
            endPoint: .top
        )

        return path.fill(gradient).blur(radius: 20)
    }
}

// MARK: - 3. Particle Background（粒子浮动）Pro
struct ParticleBackground: View {
    let primaryColor: Color

    struct Particle: Identifiable {
        let id: Int
        var x: CGFloat
        var y: CGFloat
        var radius: CGFloat
        var opacity: Double
        var speed: Double
        var phase: Double
    }

    @State private var particles: [Particle] = (0..<28).map { i in
        Particle(
            id: i,
            x: CGFloat.random(in: 0...1),
            y: CGFloat.random(in: 0...1),
            radius: CGFloat.random(in: 2...6),
            opacity: Double.random(in: 0.1...0.45),
            speed: Double.random(in: 1.8...4.0),
            phase: Double.random(in: 0...(.pi * 2))
        )
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            GeometryReader { geo in
                ZStack {
                    Color(UIColor.systemBackground)

                    ForEach(particles) { p in
                        let t = timeline.date.timeIntervalSince1970
                        let dy = sin(t / p.speed + p.phase) * 12
                        let dx = cos(t / (p.speed * 1.3) + p.phase) * 8

                        Circle()
                            .fill(primaryColor.opacity(p.opacity))
                            .frame(width: p.radius * 2, height: p.radius * 2)
                            .position(
                                x: p.x * geo.size.width + dx,
                                y: p.y * geo.size.height + dy
                            )
                            .blur(radius: p.radius > 4 ? 2 : 0)
                    }
                }
            }
        }
    }
}

// MARK: - 4. Mesh Gradient Background（渐变网格）Pro
struct MeshGradientBackground: View {
    let primaryColor: Color
    let secondaryColor: Color

    var body: some View {
        TimelineView(.animation) { timeline in
            GeometryReader { geo in
                ZStack {
                    Color(UIColor.systemBackground)
                    ForEach(0..<4) { i in
                        gradientLayer(for: i, in: geo, timeline: timeline)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func gradientLayer(for i: Int, in geo: GeometryProxy, timeline: TimelineViewDefaultContext) -> some View {
        let angle = (timeline.date.timeIntervalSince1970 * 0.3 + Double(i) * .pi / 2)
        let xOff = cos(angle) * geo.size.width * 0.3
        let yOff = sin(angle * 1.3) * geo.size.height * 0.25
        let color = i % 2 == 0 ? primaryColor : secondaryColor

        RadialGradient(
            colors: [color.opacity(0.25), color.opacity(0)],
            center: .center,
            startRadius: 10,
            endRadius: 200
        )
        .frame(width: 400, height: 400)
        .position(
            x: geo.size.width / 2 + xOff,
            y: geo.size.height / 2 + yOff
        )
        .blur(radius: 30)
    }
}

// MARK: - 5. Ripple Background（水波纹）Pro
struct RippleBackground: View {
    let primaryColor: Color

    @State private var ripples: [(id: UUID, scale: CGFloat, opacity: Double)] = []
    @State private var timer: Timer? = nil

    var body: some View {
        GeometryReader { geometry in
            rippleContent(geometry: geometry)
        }
        .onAppear(perform: startRipples)
        .onDisappear { timer?.invalidate() }
    }

    @ViewBuilder
    private func rippleContent(geometry: GeometryProxy) -> some View {
        ZStack {
            Color(UIColor.systemBackground)

            ForEach(ripples, id: \.id) { r in
                Circle()
                    .stroke(primaryColor.opacity(r.opacity), lineWidth: 1.5)
                    .scaleEffect(r.scale)
                    .frame(width: 100, height: 100)
                    .position(x: geometry.size.width / 2,
                              y: geometry.size.height * 0.4)
            }
        }
    }

    // ✅ 修复：标注 @MainActor，timer callback 用 Task { @MainActor in }
    //    替换 DispatchQueue.main.asyncAfter，保证所有 @State 操作在主线程
    @MainActor
    private func startRipples() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { _ in
            Task { @MainActor in
                let id = UUID()
                ripples.append((id: id, scale: 0.1, opacity: 0.5))

                withAnimation(.easeOut(duration: 3.0)) {
                    if let idx = ripples.firstIndex(where: { $0.id == id }) {
                        ripples[idx].scale = 5.5
                        ripples[idx].opacity = 0
                    }
                }

                try? await Task.sleep(nanoseconds: 3_200_000_000)
                ripples.removeAll { $0.id == id }
            }
        }
        timer?.fire()
    }
}

// MARK: - 6. Constellation Background（星座连线）Pro
struct ConstellationBackground: View {
    let primaryColor: Color

    struct Star: Identifiable {
        let id: Int
        let x: CGFloat
        let y: CGFloat
        let radius: CGFloat
        let twinkleSpeed: Double
    }

    let stars: [Star] = (0..<30).map { i in
        Star(
            id: i,
            x: CGFloat.random(in: 0.05...0.95),
            y: CGFloat.random(in: 0.05...0.95),
            radius: CGFloat.random(in: 1...2.5),
            twinkleSpeed: Double.random(in: 1.5...3.5)
        )
    }

    var connections: [(Int, Int)] {
        var result: [(Int, Int)] = []
        for i in 0..<stars.count {
            for j in (i+1)..<stars.count {
                let dx = stars[i].x - stars[j].x
                let dy = stars[i].y - stars[j].y
                let dist = sqrt(dx*dx + dy*dy)
                if dist < 0.2 {
                    result.append((i, j))
                }
            }
        }
        return result
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            GeometryReader { geo in
                ZStack {
                    Color(UIColor.systemBackground)

                    ForEach(connections, id: \.0) { (i, j) in
                        let s1 = stars[i]
                        let s2 = stars[j]
                        Path { path in
                            path.move(to: CGPoint(x: s1.x * geo.size.width, y: s1.y * geo.size.height))
                            path.addLine(to: CGPoint(x: s2.x * geo.size.width, y: s2.y * geo.size.height))
                        }
                        .stroke(primaryColor.opacity(0.12), lineWidth: 0.8)
                    }

                    ForEach(stars) { star in
                        let t = timeline.date.timeIntervalSince1970
                        let twinkle = (sin(t / star.twinkleSpeed) + 1) / 2 * 0.4 + 0.15

                        Circle()
                            .fill(primaryColor.opacity(twinkle))
                            .frame(width: star.radius * 2, height: star.radius * 2)
                            .position(x: star.x * geo.size.width, y: star.y * geo.size.height)
                    }
                }
            }
        }
    }
}

// MARK: - 7. Ink Background（水墨扩散）Pro
struct InkBackground: View {
    let primaryColor: Color
    let secondaryColor: Color

    var body: some View {
        TimelineView(.animation) { timeline in
            GeometryReader { geo in
                ZStack {
                    Color(UIColor.systemBackground)
                    let t = timeline.date.timeIntervalSince1970

                    Ellipse()
                        .fill(primaryColor.opacity(0.2))
                        .frame(width: 260, height: 220)
                        .blur(radius: 55)
                        .offset(x: -60 + sin(t * 0.3) * 25, y: -100 + cos(t * 0.25) * 20)

                    Ellipse()
                        .fill(secondaryColor.opacity(0.18))
                        .frame(width: 200, height: 240)
                        .blur(radius: 50)
                        .offset(x: 80 + cos(t * 0.28) * 20, y: 60 + sin(t * 0.35) * 25)

                    Circle()
                        .fill(primaryColor.opacity(0.12))
                        .frame(width: 180, height: 180)
                        .blur(radius: 45)
                        .offset(x: -30 + sin(t * 0.22) * 30, y: 120 + cos(t * 0.18) * 22)
                }
            }
        }
    }
}

// MARK: - Background Manager
class DynamicBackgroundManager: ObservableObject {
    static let shared = DynamicBackgroundManager()

    @Published var currentStyle: DynamicBackgroundStyle {
        didSet {
            UserDefaults.standard.set(currentStyle.rawValue, forKey: "dynamicBackgroundStyle")
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "dynamicBackgroundStyle") ?? "breathe"
        self.currentStyle = DynamicBackgroundStyle(rawValue: saved) ?? .breathe
    }

    func setStyle(_ style: DynamicBackgroundStyle) {
        guard isStyleUnlocked(style) else { return }
        withAnimation(.easeInOut(duration: 0.4)) {
            currentStyle = style
        }
    }

    func isStyleUnlocked(_ style: DynamicBackgroundStyle) -> Bool {
        if !style.isPro { return true }
        return ThemeManager.shared.isPro
    }
}