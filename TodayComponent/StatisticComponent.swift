//
//  StatisticComponent.swift
//  DailyReflection
//

import SwiftUI

// ============================================================
// MARK: - 全局设计系统（所有文件共享此规范）
// ============================================================
enum DS {
    // 圆角：全局统一 12pt
    static let radius:   CGFloat = 12
    // 内边距：全局统一 16pt
    static let padding:  CGFloat = 16
    // 小内边距（按钮、chip）
    static let paddingS: CGFloat = 10
    // 卡片阴影
    static let shadowColor  = Color.black.opacity(0.06)
    static let shadowRadius: CGFloat = 8

    // 背景语义
    static let cardBg = Color(.systemBackground)   // 卡片白底
    static let rowBg  = Color(.systemGray6)        // 行/子块底色

    // 强调色
    static let blue   = Color.blue
    static let purple = Color.purple
    static let green  = Color.green
    static let orange = Color.orange
    static let red    = Color.red

    // 字体规格（全局统一）
    enum T {
        // 卡片区块标题（如"统计概览"）
        static let sectionHeader = Font.system(size: 15, weight: .semibold)
        // 卡片内小标题（如"今日任务"）
        static let cardTitle     = Font.system(size: 13, weight: .medium)
        // 大数字
        static let bigNumber     = Font.system(size: 26, weight: .bold, design: .rounded)
        // 普通正文
        static let body          = Font.system(size: 15, weight: .regular)
        // 次要说明
        static let caption       = Font.system(size: 12, weight: .regular)
        // 最小标注
        static let micro         = Font.system(size: 11, weight: .medium)
    }
}

// ============================================================
// MARK: - 通用卡片容器（统一投影+圆角）
// ============================================================
struct DSCard<Content: View>: View {
    var padding: CGFloat = DS.padding
    @ViewBuilder let content: () -> Content
    var body: some View {
        content()
            .padding(padding)
            .background(DS.cardBg)
            .cornerRadius(DS.radius)
            .shadow(color: DS.shadowColor, radius: DS.shadowRadius, x: 0, y: 2)
    }
}

// ============================================================
// MARK: - StatCard：任务完成统计
// ============================================================
struct StatCard: View {
    let totalTasks: Int
    let completedTasks: Int
    let percentage: Int
    let totalDuration: Double
    let completedDuration: Double

    var body: some View {
        DSCard {
            HStack(alignment: .center, spacing: DS.padding) {

                VStack(alignment: .leading, spacing: 6) {
                    Text("今日任务")
                        .font(DS.T.cardTitle)
                        .foregroundColor(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(completedTasks)")
                            .font(DS.T.bigNumber)
                        Text("/\(totalTasks)")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    Text("\(Int(completedDuration)) / \(Int(totalDuration)) 分钟")
                        .font(DS.T.caption)
                        .foregroundColor(DS.blue)
                }

                Spacer()

                RingProgress(percentage: percentage)
                    .frame(width: 60, height: 60)
            }
        }
    }
}

// ============================================================
// MARK: - 环形进度（统一尺寸和线宽）
// ============================================================
struct RingProgress: View {
    let percentage: Int
    private var color: Color { percentage == 100 ? DS.green : DS.blue }

    var body: some View {
        ZStack {
            Circle()
                .stroke(DS.rowBg, lineWidth: 7)
            Circle()
                .trim(from: 0, to: CGFloat(percentage) / 100)
                .stroke(color, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.4), value: percentage)
            Text("\(percentage)%")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
    }
}

// ⚠️ 保留旧名兼容
typealias CircularProgressView = RingProgress

// ============================================================
// MARK: - CategoryTimeChart：时长分布
// ============================================================
struct CategoryTimeChart: View {
    let categoryDurations: [(category: String, duration: Double, percentage: Double)]

    private let colorMap: [String: Color] = [
        "工作": .blue, "学习": .green, "健身": .orange, "娱乐": .purple, "其他": .gray
    ]

    var body: some View {
        DSCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionLabel("时长分布", icon: "chart.bar.fill", color: DS.blue)

                VStack(spacing: 10) {
                    ForEach(categoryDurations, id: \.category) { item in
                        let c = colorMap[item.category] ?? .gray
                        HStack(spacing: 10) {
                            // 色点 + 分类名
                            HStack(spacing: 5) {
                                Circle().fill(c).frame(width: 7, height: 7)
                                Text(item.category)
                                    .font(DS.T.micro)
                                    .foregroundColor(.primary)
                                    .frame(width: 32, alignment: .leading)
                            }
                            // 进度条
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(DS.rowBg).frame(height: 7)
                                    Capsule()
                                        .fill(c)
                                        .frame(width: geo.size.width * CGFloat(item.percentage / 100), height: 7)
                                }
                            }
                            .frame(height: 7)
                            // 时长
                            VStack(alignment: .trailing, spacing: 1) {
                                Text("\(Int(item.duration))分")
                                    .font(DS.T.micro)
                                Text("\(Int(item.percentage))%")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 42, alignment: .trailing)
                        }
                    }
                }
            }
        }
    }
}

// ============================================================
// MARK: - CaloriesSummaryBox：卡路里统计
// ============================================================
struct CaloriesSummaryBox: View {
    let burned: Double
    let consumed: Double
    let net: Double

    var body: some View {
        DSCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionLabel("卡路里统计", icon: "flame.fill", color: DS.orange)

                HStack(spacing: 0) {
                    metricItem(label: "消耗", value: "\(Int(burned))", unit: "卡", color: DS.orange)
                    Divider().frame(height: 38).padding(.horizontal, 14)
                    metricItem(label: "摄入", value: "\(Int(consumed))", unit: "卡", color: DS.green)
                    Spacer()
                }

                Divider()

                netRow(label: "净消耗", value: "\(Int(net)) 卡",
                       positive: net >= 0, positiveColor: DS.blue)
            }
        }
    }
}

// ============================================================
// MARK: - FinanceSummaryBox：财务统计
// ============================================================
struct FinanceSummaryBox: View {
    let totalRevenue: Double
    let totalExpense: Double
    let netIncome: Double

    var body: some View {
        DSCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionLabel("财务统计", icon: "yensign.circle.fill", color: DS.green)

                HStack(spacing: 0) {
                    metricItem(label: "总收入",
                               value: "¥\(String(format:"%.0f", totalRevenue))",
                               unit: nil, color: DS.green)
                    Divider().frame(height: 38).padding(.horizontal, 14)
                    metricItem(label: "总支出",
                               value: "¥\(String(format:"%.0f", totalExpense))",
                               unit: nil, color: DS.red)
                    Spacer()
                }

                Divider()

                netRow(label: "净收入",
                       value: "¥\(String(format:"%.2f", netIncome))",
                       positive: netIncome >= 0, positiveColor: DS.blue)
            }
        }
    }
}

// ============================================================
// MARK: - 共用子组件（私有，避免外部污染）
// ============================================================

private func sectionLabel(_ title: String, icon: String, color: Color) -> some View {
    HStack(spacing: 7) {
        Image(systemName: icon)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(color)
        Text(title)
            .font(DS.T.cardTitle)
            .foregroundColor(.secondary)
    }
}

private func metricItem(label: String, value: String, unit: String?, color: Color) -> some View {
    VStack(alignment: .leading, spacing: 3) {
        Text(label)
            .font(DS.T.caption)
            .foregroundColor(.secondary)
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(color)
            if let unit = unit {
                Text(unit)
                    .font(DS.T.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

private func netRow(label: String, value: String, positive: Bool, positiveColor: Color) -> some View {
    HStack {
        Text(label)
            .font(DS.T.cardTitle)
            .foregroundColor(.secondary)
        Spacer()
        Text(value)
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundColor(positive ? positiveColor : DS.red)
    }
}
