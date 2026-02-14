import SwiftUI

struct SubscriptionView: View {
    @State private var selectedPlan: SubscriptionPlan = .pro
    @Environment(\.dismiss) var dismiss
    
    enum SubscriptionPlan {
        case monthlyBasic, basic, pro
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 头部
                VStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.yellow)
                    
                    Text("解锁全部功能")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("选择适合你的订阅方案")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // 订阅卡片
                VStack(spacing: 16) {
                    // 月度基础版
                    SubscriptionCard(
                        title: "基础版月付",
                        price: "¥6",
                        period: "/ 月",
                        badge: "首月¥1",
                        features: [
                            "无限任务",
                            "完整日历视图",
                            "任务复盘",
                            "锁屏组件",
                            "项目DDL管理"
                        ],
                        isSelected: selectedPlan == .monthlyBasic,
                        color: .green
                    ) {
                        selectedPlan = .monthlyBasic
                    }
                    
                    // 年度基础版
                    SubscriptionCard(
                        title: "基础版年付",
                        price: "¥68",
                        period: "/ 年",
                        badge: "省¥4",
                        features: [
                            "月付全部功能",
                            "相当于¥5.7/月",
                            "连续包年更优惠"
                        ],
                        isSelected: selectedPlan == .basic,
                        color: .blue
                    ) {
                        selectedPlan = .basic
                    }
                    
                    // Pro版
                    SubscriptionCard(
                        title: "Pro版",
                        price: "¥98",
                        period: "/ 年",
                        badge: "推荐",
                        features: [
                            "基础版全部功能",
                            "AI智能规划助手",
                            "AI自动总结",
                            "完整白噪音库（20+）",
                            "所有主题皮肤",
                            "优先客服支持"
                        ],
                        isSelected: selectedPlan == .pro,
                        color: .purple
                    ) {
                        selectedPlan = .pro
                    }
                }
                .padding(.horizontal)
                
                // 功能对比
                VStack(alignment: .leading, spacing: 16) {
                    Text("功能对比")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    FeatureComparisonRow(
                        feature: "每日任务数",
                        free: "7个",
                        basic: "无限",
                        pro: "无限"
                    )
                    
                    FeatureComparisonRow(
                        feature: "历史记录",
                        free: "7天",
                        basic: "永久",
                        pro: "永久"
                    )
                    
                    FeatureComparisonRow(
                        feature: "白噪音",
                        free: "3个",
                        basic: "3个",
                        pro: "20+"
                    )
                    
                    FeatureComparisonRow(
                        feature: "AI助手",
                        free: "❌",
                        basic: "❌",
                        pro: "✅"
                    )
                    
                    FeatureComparisonRow(
                        feature: "主题皮肤",
                        free: "1个",
                        basic: "1个",
                        pro: "全部"
                    )
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // 购买按钮
                Button(action: {
                    // TODO: 实现StoreKit购买
                    print("购买: \(selectedPlan)")
                }) {
                    Text(buttonText)
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(buttonColor)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // 说明文字
                VStack(spacing: 8) {
                    Text("• 通过苹果App Store支付")
                    Text("• 订阅自动续费，可随时取消")
                    Text("• 支持家庭共享")
                    Text("• 7天无理由退款")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                // 恢复购买
                Button("恢复购买") {
                    // TODO: 恢复购买
                }
                .font(.subheadline)
                .foregroundColor(.blue)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("订阅")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    var buttonText: String {
        switch selectedPlan {
        case .monthlyBasic:
            return "订阅月付 - 首月¥1"
        case .basic:
            return "订阅年付 - ¥68/年"
        case .pro:
            return "订阅Pro版 - ¥98/年"
        }
    }
    
    var buttonColor: Color {
        switch selectedPlan {
        case .monthlyBasic:
            return .green
        case .basic:
            return .blue
        case .pro:
            return .purple
        }
    }
}

struct SubscriptionCard: View {
    let title: String
    let price: String
    let period: String
    var badge: String? = nil
    let features: [String]
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(title)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            if let badge = badge {
                                Text(badge)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange)
                                    .cornerRadius(4)
                            }
                        }
                        
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(price)
                                .font(.system(size: 32, weight: .bold))
                            Text(period)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelected ? color : .gray)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(features, id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .foregroundColor(color)
                            Text(feature)
                                .font(.subheadline)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? color : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? color.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

struct FeatureComparisonRow: View {
    let feature: String
    let free: String
    let basic: String
    let pro: String
    
    var body: some View {
        HStack {
            Text(feature)
                .font(.subheadline)
                .frame(width: 80, alignment: .leading)
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("免费")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(free)
                    .font(.caption)
            }
            .frame(width: 60)
            
            VStack(spacing: 4) {
                Text("基础")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(basic)
                    .font(.caption)
            }
            .frame(width: 60)
            
            VStack(spacing: 4) {
                Text("Pro")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(pro)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .frame(width: 60)
        }
    }
}
