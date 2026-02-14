//
//  CollapsibleStatisticsBox.swift
//  DailyReflection
//

import SwiftUI

struct CollapsibleStatisticsBox: View {
    @Binding var isExpanded: Bool
    let calculations: TodayCalculations

    var body: some View {
        VStack(spacing: 0) {

            // ── 标题行 ──────────────────────────────────────
            Button {
                withAnimation(.easeInOut(duration: 0.25)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DS.blue)
                    Text("统计概览")
                        .font(DS.T.sectionHeader)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, DS.padding)
                .padding(.vertical, 13)
            }
            .buttonStyle(.plain)

            // ── 展开内容 ────────────────────────────────────
            if isExpanded {
                VStack(spacing: 10) {

                    StatCard(
                        totalTasks: calculations.totalTasks,
                        completedTasks: calculations.completedTasks,
                        percentage: calculations.completionPercentage,
                        totalDuration: calculations.totalDuration,
                        completedDuration: calculations.completedDuration
                    )

                    if !calculations.categoryDurations.isEmpty {
                        CategoryTimeChart(categoryDurations: calculations.categoryDurations)
                    }

                    FinanceSummaryBox(
                        totalRevenue: calculations.totalRevenue,
                        totalExpense: calculations.totalExpense,
                        netIncome: calculations.netIncome
                    )

                    CaloriesSummaryBox(
                        burned: calculations.totalCaloriesBurned,
                        consumed: calculations.totalCaloriesConsumed,
                        net: calculations.netCalories
                    )
                }
                .padding(.horizontal, DS.padding)
                .padding(.bottom, DS.padding)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        // 外层卡片样式
        .background(DS.cardBg)
        .cornerRadius(DS.radius)
        .shadow(color: DS.shadowColor, radius: DS.shadowRadius, x: 0, y: 2)
    }
}
