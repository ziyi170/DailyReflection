// DailyReflectionLiveActivity.swift
// 灵动岛 (Dynamic Island) 和锁屏 Live Activity 实现

import WidgetKit
import SwiftUI
import ActivityKit

@available(iOS 16.1, *)
struct DailyReflectionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DailyReflectionAttributes.self) { context in
            // 锁屏和通知中心的显示视图
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            // 灵动岛配置
            DynamicIsland {
                // MARK: - 展开状态
                
                // 前导区域（左侧）
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label {
                            Text(context.state.currentTask)
                                .font(.caption)
                                .lineLimit(1)
                        } icon: {
                            Image(systemName: context.state.isAllCompleted ? "checkmark.circle.fill" : "circle.dotted")
                                .foregroundColor(context.state.isAllCompleted ? .green : .cyan)
                        }
                        
                        Text("当前任务")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 尾随区域（右侧）
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(context.state.completedCount)/\(context.state.totalCount)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(context.state.isAllCompleted ? .green : .primary)
                        
                        Text("已完成")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 中心区域
                DynamicIslandExpandedRegion(.center) {
                    // 可以添加额外内容，这里留空
                    EmptyView()
                }
                
                // 底部区域
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        // 进度条
                        ProgressView(value: context.state.progress)
                            .progressViewStyle(.linear)
                            .tint(context.state.isAllCompleted ? .green : .cyan)
                        
                        // 底部信息栏
                        HStack {
                            Label(context.state.mood, systemImage: moodIcon(for: context.state.mood))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(context.state.lastUpdate, style: .relative)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }
            } compactLeading: {
                // MARK: - 紧凑型前导（左侧小图标）
                HStack(spacing: 3) {
                    Image(systemName: context.state.isAllCompleted ? "checkmark.circle.fill" : "circle.dotted")
                        .foregroundColor(context.state.isAllCompleted ? .green : .cyan)
                        .font(.caption2)
                    
                    Text("\(context.state.completedCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                }
            } compactTrailing: {
                // MARK: - 紧凑型尾随（右侧小图标）
                Text("\(context.state.totalCount)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } minimal: {
                // MARK: - 最小化状态（单个图标）
                Image(systemName: context.state.isAllCompleted ? "checkmark.circle.fill" : "circle.dotted")
                    .foregroundColor(context.state.isAllCompleted ? .green : .cyan)
            }
            .widgetURL(URL(string: "dailyreflection://tasks"))
            .keylineTint(context.state.isAllCompleted ? .green : .cyan)
        }
    }
    
    /// 根据心情返回对应的 SF Symbol 图标
    private func moodIcon(for mood: String) -> String {
        switch mood {
        case "开心", "快乐", "愉快":
            return "face.smiling"
        case "平静", "放松", "安宁":
            return "moon.stars"
        case "疲惫", "疲劳", "困倦":
            return "powersleep"
        case "焦虑", "紧张", "压力":
            return "exclamationmark.triangle"
        case "专注", "认真":
            return "brain.head.profile"
        default:
            return "face.smiling"
        }
    }
}

// MARK: - 锁屏视图

@available(iOS 16.1, *)
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<DailyReflectionAttributes>
    
    var body: some View {
        VStack(spacing: 12) {
            // 顶部信息栏
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.cyan)
                    .font(.title3)
                
                Text("Hello, \(context.attributes.username)")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Label(context.state.mood, systemImage: moodIcon(for: context.state.mood))
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            
            // 当前任务区域
            VStack(alignment: .leading, spacing: 4) {
                Text("当前任务")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: context.state.isAllCompleted ? "checkmark.circle.fill" : "circle.dotted")
                        .foregroundColor(context.state.isAllCompleted ? .green : .cyan)
                    
                    Text(context.state.currentTask)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 进度区域
            VStack(spacing: 6) {
                // 进度条
                ProgressView(value: context.state.progress)
                    .progressViewStyle(.linear)
                    .tint(context.state.isAllCompleted ? .green : .cyan)
                
                // 进度信息
                HStack {
                    Text("\(context.state.completedCount) / \(context.state.totalCount) 已完成")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(context.state.progressText)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(context.state.isAllCompleted ? .green : .cyan)
                    
                    Text("·")
                        .foregroundColor(.secondary)
                    
                    Text(context.state.lastUpdate, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .activityBackgroundTint(.cyan.opacity(0.1))
        .activitySystemActionForegroundColor(.cyan)
    }
    
    /// 根据心情返回对应的 SF Symbol 图标
    private func moodIcon(for mood: String) -> String {
        switch mood {
        case "开心", "快乐", "愉快":
            return "face.smiling"
        case "平静", "放松", "安宁":
            return "moon.stars"
        case "疲惫", "疲劳", "困倦":
            return "powersleep"
        case "焦虑", "紧张", "压力":
            return "exclamationmark.triangle"
        case "专注", "认真":
            return "brain.head.profile"
        default:
            return "face.smiling"
        }
    }
}

// MARK: - 预览
#Preview("Live Activity", as: .content, using: DailyReflectionAttributes(username: "小明", startTime: Date())) {
    DailyReflectionLiveActivity()
} contentStates: {
    DailyReflectionAttributes.ContentState(
        currentTask: "完成项目文档",
        completedCount: 3,
        totalCount: 5,
        mood: "专注",
        lastUpdate: Date()
    )
    
    DailyReflectionAttributes.ContentState(
        currentTask: "所有任务已完成！",
        completedCount: 5,
        totalCount: 5,
        mood: "开心",
        lastUpdate: Date()
    )
}
