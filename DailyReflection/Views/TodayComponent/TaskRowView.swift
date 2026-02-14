//
//  TaskRowView.swift
//  DailyReflection
//
//  Created by 小艺 on 2026/1/31.
import SwiftUI

struct TaskInfoView: View {
    let title: String
    let isCompleted: Bool
    let timeRange: String
    let duration: String
    let netIncome: String?
    let category: String  // 添加分类显示
    let hasWhiteNoise: Bool  // 添加白噪音图标
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.headline)
                    .strikethrough(isCompleted)
                    .foregroundColor(isCompleted ? .secondary : .primary)
                
                Spacer()
                
                if netIncome != nil {
                    Text(netIncome!)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            (Double(netIncome!.replacingOccurrences(of: "¥", with: "")) ?? 0) >= 0
                            ? Color.green.opacity(0.2)
                            : Color.red.opacity(0.2)
                        )
                        .cornerRadius(4)
                }
            }
            
            HStack(spacing: 12) {
                Label(timeRange, systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !duration.isEmpty {
                    Text("·")
                    Label(duration, systemImage: "hourglass")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if !category.isEmpty {
                    Text("·")
                    Label(category, systemImage: "tag")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if hasWhiteNoise {
                    Image(systemName: "ear.and.waveform")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
    }
}
