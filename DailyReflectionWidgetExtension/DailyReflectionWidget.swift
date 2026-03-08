//
//  DailyReflectionWidget.swift
//  DailyReflectionWidgetExtension
//
//  主屏幕 Widget（支持小、中、大尺寸）
//  ✅ 修复：补全 switch case，移除 <#code#> 占位符

import WidgetKit
import SwiftUI

// MARK: - Widget Configuration
struct DailyReflectionWidget: Widget {
    let kind: String = "DailyReflectionWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TaskProvider()) { entry in
            MainWidgetView(entry: entry)
        }
        .configurationDisplayName("每日复盘")
        .description("查看今日任务进度")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Main Widget View
struct MainWidgetView: View {
    var entry: TaskEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            switch family {
            // ✅ 修复：补全原来缺失的 case
            case .systemSmall:
                SmallMainWidget(entry: entry)
            case .systemMedium:
                MediumMainWidget(entry: entry)
            case .systemLarge:
                LargeMainWidget(entry: entry)
            // ✅ 修复：移除 <#code#>，用 LargeMainWidget 复用
            case .systemExtraLarge:
                LargeMainWidget(entry: entry)
            // 锁屏尺寸不在 supportedFamilies 中，不会实际触发
            case .accessoryCircular, .accessoryRectangular, .accessoryInline:
                EmptyView()
            @unknown default:
                SmallMainWidget(entry: entry)
            }
        }
        .widgetBackground(Color(.systemBackground))
        .widgetURL(URL(string: "dailyreflection://today"))
    }
}

// MARK: - Small Main Widget
struct SmallMainWidget: View {
    let entry: TaskEntry

    private var progress: Double {
        guard entry.tasks.count > 0 else { return 0 }
        return Double(entry.completedCount) / Double(entry.tasks.count)
    }

    private var isAllCompleted: Bool {
        entry.tasks.count > 0 && entry.completedCount >= entry.tasks.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("📝").font(.title3)
                Spacer()
                Text("\(entry.completedCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(isAllCompleted ? .green : .blue)
            }

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        isAllCompleted ? Color.green : Color.blue,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("完成")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)

            Spacer()

            if let nextTask = entry.tasks.first(where: { !$0.isCompleted }) {
                Text(nextTask.title)
                    .font(.caption2)
                    .lineLimit(1)
                    .foregroundColor(.primary)
            } else if isAllCompleted && entry.tasks.count > 0 {
                Text("🎉 已完成")
                    .font(.caption2)
                    .foregroundColor(.green)
            } else {
                Text("今日复盘")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

// MARK: - Medium Main Widget
struct MediumMainWidget: View {
    let entry: TaskEntry

    private var progress: Double {
        guard entry.tasks.count > 0 else { return 0 }
        return Double(entry.completedCount) / Double(entry.tasks.count)
    }

    private var nextTask: WidgetTask? {
        entry.tasks.first(where: { !$0.isCompleted })
    }

    var body: some View {
        HStack(spacing: 16) {
            // 左侧：进度和统计
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("今日复盘")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(entry.username)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("进度")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(entry.completedCount)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text("/\(entry.tasks.count)")
                            .font(.body)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .font(.headline)
                            .foregroundColor(progress > 0.7 ? .green : .blue)
                    }

                    ProgressView(value: progress)
                        .tint(progress > 0.7 ? .green : .blue)
                        .progressViewStyle(.linear)
                }
            }

            Divider().frame(width: 1)

            // 右侧：当前任务
            VStack(alignment: .leading, spacing: 12) {
                Text("当前任务")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let nextTask = nextTask {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "circle")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Text(nextTask.title)
                                .font(.body)
                                .lineLimit(2)
                        }
                        Text(formatTime(nextTask.startTime))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } else if entry.tasks.count > 0 && entry.completedCount >= entry.tasks.count {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                        Text("全部完成")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Text("暂无任务")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                Spacer()

                Text("心情: \(entry.mood)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f.string(from: date)
    }
}

// MARK: - Large Main Widget
struct LargeMainWidget: View {
    let entry: TaskEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("每日复盘")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(entry.username)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                HStack(spacing: 8) {
                    Label(entry.mood, systemImage: "face.smiling")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    Text("\(entry.completedCount)/\(entry.tasks.count)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("任务进度").font(.headline)
                ProgressView(value: Double(entry.completedCount) / Double(max(entry.tasks.count, 1)))
                    .progressViewStyle(.linear)
                    .tint(.blue)
                HStack {
                    Text("\(entry.completedCount) 已完成")
                        .font(.caption).foregroundColor(.green)
                    Spacer()
                    Text("\(entry.tasks.count - entry.completedCount) 待完成")
                        .font(.caption).foregroundColor(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("任务列表").font(.headline)

                if entry.tasks.isEmpty {
                    Text("今日暂无任务安排")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                } else {
                    ForEach(entry.tasks.prefix(4)) { task in
                        HStack {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(task.isCompleted ? .green : .gray)
                            Text(task.title)
                                .font(.body)
                                .strikethrough(task.isCompleted)
                                .lineLimit(1)
                            Spacer()
                            Text(formatTime(task.startTime))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }

                    if entry.tasks.count > 4 {
                        Text("还有 \(entry.tasks.count - 4) 个任务...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding()
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f.string(from: date)
    }
}

// MARK: - Preview
#Preview("小尺寸", as: .systemSmall) {
    DailyReflectionWidget()
} timeline: {
    TaskEntry(
        date: Date(),
        tasks: [
            WidgetTask(id: UUID(), title: "晨会", date: Date(), startTime: Date(), isCompleted: true),
            WidgetTask(id: UUID(), title: "代码开发", date: Date(), startTime: Date(), isCompleted: true),
            WidgetTask(id: UUID(), title: "项目会议", date: Date(), startTime: Date(), isCompleted: false)
        ],
        completedCount: 2,
        mood: "专注",
        username: "小明"
    )
}

#Preview("中尺寸", as: .systemMedium) {
    DailyReflectionWidget()
} timeline: {
    TaskEntry(
        date: Date(),
        tasks: [
            WidgetTask(id: UUID(), title: "晨会", date: Date(), startTime: Date(), isCompleted: true),
            WidgetTask(id: UUID(), title: "代码开发", date: Date(), startTime: Date(), isCompleted: true),
            WidgetTask(id: UUID(), title: "项目会议", date: Date(), startTime: Date(), isCompleted: false),
            WidgetTask(id: UUID(), title: "撰写文档", date: Date(), startTime: Date(), isCompleted: false)
        ],
        completedCount: 2,
        mood: "平静",
        username: "小明"
    )
}

#Preview("大尺寸", as: .systemLarge) {
    DailyReflectionWidget()
} timeline: {
    TaskEntry(
        date: Date(),
        tasks: [
            WidgetTask(id: UUID(), title: "晨会", date: Date(), startTime: Date(), isCompleted: true),
            WidgetTask(id: UUID(), title: "代码开发", date: Date(), startTime: Date(), isCompleted: true),
            WidgetTask(id: UUID(), title: "项目会议", date: Date(), startTime: Date(), isCompleted: false),
            WidgetTask(id: UUID(), title: "撰写文档", date: Date(), startTime: Date(), isCompleted: false),
            WidgetTask(id: UUID(), title: "健身运动", date: Date(), startTime: Date(), isCompleted: false)
        ],
        completedCount: 2,
        mood: "愉快",
        username: "小明"
    )
}