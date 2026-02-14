//
//  EmptyStateView.swift
//  DailyReflection
//

import SwiftUI

struct EmptyStateViewWithSmartAdd: View {
    @Binding var showingAddTask: Bool
    @Binding var showingSmartAdd: Bool

    var body: some View {
        VStack(spacing: 18) {

            // 图标
            ZStack {
                Circle()
                    .fill(DS.blue.opacity(0.08))
                    .frame(width: 72, height: 72)
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundColor(DS.blue.opacity(0.65))
            }

            // 文案
            VStack(spacing: 5) {
                Text("还没有任务")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                Text("选择一种方式开始规划今天")
                    .font(DS.T.caption)
                    .foregroundColor(.secondary)
            }

            // 按钮
            VStack(spacing: 9) {
                // 主按钮
                Button { showingSmartAdd = true } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .semibold))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("智能添加")
                                .font(.system(size: 14, weight: .semibold))
                            Text("拍照 · 语音快速录入")
                                .font(.system(size: 11))
                                .opacity(0.85)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .medium))
                            .opacity(0.7)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, DS.padding)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color(red:0.2,green:0.4,blue:1.0),
                                     Color(red:0.5,green:0.2,blue:0.9)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .cornerRadius(DS.radius)
                }
                .buttonStyle(.plain)

                // 次级按钮
                Button { showingAddTask = true } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 13, weight: .medium))
                        Text("手动输入")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(DS.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(DS.blue.opacity(0.08))
                    .cornerRadius(DS.radius)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, DS.padding)
        .padding(.vertical, 24)
    }
}
