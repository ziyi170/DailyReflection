// [file name]: DailyReflectionLockWidget.swift
// [file content begin]
//
//  DailyReflectionLockWidget.swift
//  DailyReflectionWidgetExtension
//
//  锁屏组件（Lock Screen Widget）实现
//

import WidgetKit
import SwiftUI

// MARK: - Widget Configuration
struct DailyReflectionLockWidget: Widget {
    let kind: String = "DailyReflectionLockWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TaskProvider()) { entry in
            LockScreenWidgetView(entry: entry)
        }
        .configurationDisplayName("任务进度")
        .description("在锁屏显示任务完成进度")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// MARK: - Main View
struct LockScreenWidgetView: View {
    var entry: TaskEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularLockView(entry: entry)
        case .accessoryRectangular:
            RectangularLockView(entry: entry)
        case .accessoryInline:
            InlineLockView(entry: entry)
        case .systemSmall, .systemMedium, .systemLarge, .systemExtraLarge:
            EmptyView()
        @unknown default:
            EmptyView()
        }
    }
}

// MARK: - Circular
struct CircularLockView: View {
    let entry: TaskEntry
    
    private var progress: Double {
        guard entry.tasks.count > 0 else { return 0 }
        return Double(entry.completedCount) / Double(entry.tasks.count)
    }
    
    private var isCompleted: Bool {
        entry.tasks.count > 0 && entry.completedCount >= entry.tasks.count
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 4)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    isCompleted ? Color.green : Color.cyan,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            VStack(spacing: 1) {
                Text("\(entry.completedCount)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(isCompleted ? .green : .primary)
                
                Text("/\(entry.tasks.count)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .widgetAccentable()
        .containerBackground(.background, for: .widget)
    }
}

// MARK: - Rectangular
struct RectangularLockView: View {
    let entry: TaskEntry
    
    private var progress: Double {
        guard entry.tasks.count > 0 else { return 0 }
        return Double(entry.completedCount) / Double(entry.tasks.count)
    }
    
    // ✅ 当前正在进行的任务（按时间匹配）
    private var currentTask: WidgetTask? {
        let now = Date()
        return entry.tasks.first(where: { !$0.isCompleted && $0.startTime <= now })
            ?? entry.tasks.first(where: { !$0.isCompleted })
    }
    
    private var isCompleted: Bool {
        entry.tasks.count > 0 && entry.completedCount >= entry.tasks.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 第一行：标题 + 进度数字
            HStack {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle.dotted")
                    .foregroundColor(isCompleted ? .green : .cyan)
                    .font(.system(size: 12))
                Text(isCompleted ? "全部完成 🎉" : "今日任务")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("\(entry.completedCount)/\(entry.tasks.count)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(isCompleted ? .green : .primary)
            }
            
            // 第二行：进度条
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(isCompleted ? .green : .cyan)
            
            // 第三行：当前任务名（核心信息）
            if let task = currentTask {
                HStack(spacing: 4) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.cyan)
                    Text(task.title)
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                        .foregroundColor(.primary)
                }
            } else if isCompleted {
                Text("今日任务全部完成！")
                    .font(.system(size: 11))
                    .foregroundColor(.green)
            } else {
                Text("暂无进行中的任务")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .widgetAccentable()
        .containerBackground(.background, for: .widget)
    }
}

// MARK: - Inline
struct InlineLockView: View {
    let entry: TaskEntry
    
    private var isCompleted: Bool {
        entry.tasks.count > 0 && entry.completedCount >= entry.tasks.count
    }
    
    var body: some View {
        if isCompleted {
            Text("✅ \(entry.completedCount)/\(entry.tasks.count) 任务 · 全部完成")
        } else {
            Text("📝 \(entry.completedCount)/\(entry.tasks.count) 任务 · \(entry.mood)")
        }
    }
}

// MARK: - Preview
#Preview("圆形", as: .accessoryCircular) {
    DailyReflectionLockWidget()
} timeline: {
    TaskEntry(
        date: Date(),
        tasks: [
            WidgetTask(id: UUID(), title: "完成工作报告", date: Date(), startTime: Date(), isCompleted: true),
            WidgetTask(id: UUID(), title: "阅读书籍", date: Date(), startTime: Date(), isCompleted: true),
            WidgetTask(id: UUID(), title: "运动", date: Date(), startTime: Date(), isCompleted: false)
        ],
        completedCount: 2,
        mood: "专注",
        username: "小明"
    )
}

#Preview("矩形", as: .accessoryRectangular) {
    DailyReflectionLockWidget()
} timeline: {
    TaskEntry(
        date: Date(),
        tasks: [
            WidgetTask(id: UUID(), title: "完成项目文档整理", date: Date(), startTime: Date(), isCompleted: false),
            WidgetTask(id: UUID(), title: "团队会议", date: Date(), startTime: Date(), isCompleted: true)
        ],
        completedCount: 1,
        mood: "平静",
        username: "小明"
    )
}

#Preview("内联", as: .accessoryInline) {
    DailyReflectionLockWidget()
} timeline: {
    TaskEntry(
        date: Date(),
        tasks: [
            WidgetTask(id: UUID(), title: "任务1", date: Date(), startTime: Date(), isCompleted: true),
            WidgetTask(id: UUID(), title: "任务2", date: Date(), startTime: Date(), isCompleted: false)
        ],
        completedCount: 1,
        mood: "开心",
        username: "小明"
    )
}
// [file content end]