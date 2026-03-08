// DailyReflectionLiveActivity.swift
// 灵动岛 —— 音乐播放器风格，支持长按展开、暂停/跳过/添加任务

import WidgetKit
import SwiftUI
import ActivityKit
import AppIntents

@available(iOS 16.2, *)
struct DailyReflectionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DailyReflectionAttributes.self) { context in
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {

                // ============================================================
                // MARK: - 展开状态（长按后显示，对标 QQ 音乐播放器）
                // ============================================================

                // 左侧：App 图标 + 当前任务名
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.cyan, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)
                            Image(systemName: context.state.hasTasks
                                  ? "checkmark.circle" : "plus.circle")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.state.hasTasks ? "进行中" : "今日任务")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(context.state.hasTasks
                                 ? context.state.currentTask : "点击添加任务")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                                .foregroundColor(context.state.isAllCompleted ? .green : .primary)
                        }
                    }
                }

                // 右侧：进度 badge
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.hasTasks {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(context.state.completedCount)/\(context.state.totalCount)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(context.state.isAllCompleted ? .green : .cyan)
                            Text("已完成")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // 中心：进度百分比（必须有内容，否则系统禁用长按）
                DynamicIslandExpandedRegion(.center) {
                    if context.state.hasTasks {
                        VStack(spacing: 1) {
                            Text(context.state.progressText)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(context.state.isAllCompleted ? .green : .cyan)
                            Text(context.state.isAllCompleted ? "全部完成 🎉" : "今日进度")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // 底部：控制栏（核心交互区，对标音乐播放器）
                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.hasTasks && !context.state.isAllCompleted {
                        // ── 有任务且未全部完成 ──────────────────────────
                        VStack(spacing: 10) {

                            // 进度条
                            ProgressView(value: context.state.progress)
                                .progressViewStyle(.linear)
                                .tint(.cyan)
                                .padding(.horizontal, 4)

                            // 下一个任务预告
                            if !context.state.nextTask.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.right.circle")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text("下一个：\(context.state.nextTask)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 4)
                            }

                            // 四个控制按钮（暂停 · 完成 · 跳过 · 添加）
                            HStack(spacing: 0) {

                                // 暂停 / 继续
                                Button(intent: PauseTaskIntent()) {
                                    VStack(spacing: 3) {
                                        Image(systemName: context.state.isTimerRunning
                                              ? "pause.circle.fill" : "play.circle.fill")
                                            .font(.system(size: 30))
                                            .foregroundColor(.cyan)
                                        Text(context.state.isTimerRunning ? "暂停" : "继续")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                                .frame(maxWidth: .infinity)

                                // 完成当前任务
                                Button(intent: CompleteTaskIntent()) {
                                    VStack(spacing: 3) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 30))
                                            .foregroundColor(.green)
                                        Text("完成")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                                .frame(maxWidth: .infinity)

                                // 跳过（完成当前，切换下一个）
                                Button(intent: SkipTaskIntent()) {
                                    VStack(spacing: 3) {
                                        Image(systemName: "forward.end.circle.fill")
                                            .font(.system(size: 30))
                                            .foregroundColor(.orange)
                                        Text("跳过")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                                .frame(maxWidth: .infinity)

                                // 添加新任务（跳转 App）
                                Link(destination: URL(string: "dailyreflection://add-task")!) {
                                    VStack(spacing: 3) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 30))
                                            .foregroundColor(.blue)
                                        Text("添加")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.horizontal, 8)
                            .padding(.bottom, 4)
                        }

                    } else if context.state.isAllCompleted {
                        // ── 全部完成状态 ──────────────────────────────
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.title2)
                                    .foregroundColor(.green)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("今日任务全部完成！🎉")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text("轻点添加明日任务")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Link(destination: URL(string: "dailyreflection://add-task")!) {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("添加新任务")
                                        .fontWeight(.semibold)
                                }
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    LinearGradient(
                                        colors: [.cyan, .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    in: RoundedRectangle(cornerRadius: 12)
                                )
                            }
                            .padding(.horizontal, 8)
                        }
                        .padding(.bottom, 4)

                    } else {
                        // ── 无任务状态：引导添加 ──────────────────────
                        Link(destination: URL(string: "dailyreflection://add-task")!) {
                            HStack(spacing: 10) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.cyan)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("今日还没有任务")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text("轻点这里，添加第一个任务 →")
                                        .font(.caption2)
                                        .foregroundColor(.cyan)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(.cyan.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                            .padding(.horizontal, 4)
                            .padding(.bottom, 4)
                        }
                    }
                }

            } compactLeading: {
                // ── 紧凑型左侧 ────────────────────────────────────────
                HStack(spacing: 3) {
                    Image(systemName: context.state.isAllCompleted
                          ? "checkmark.circle.fill"
                          : (context.state.hasTasks ? "circle.dotted" : "plus.circle"))
                        .foregroundColor(context.state.isAllCompleted ? .green : .cyan)
                        .font(.caption)
                    if context.state.hasTasks {
                        Text("\(context.state.completedCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.cyan)
                    }
                }

            } compactTrailing: {
                // ── 紧凑型右侧 ────────────────────────────────────────
                if context.state.hasTasks {
                    Text(context.state.isAllCompleted ? "✓" : "\(context.state.totalCount)")
                        .font(.caption2)
                        .foregroundColor(context.state.isAllCompleted ? .green : .secondary)
                } else {
                    Image(systemName: "plus")
                        .font(.caption2)
                        .foregroundColor(.cyan)
                }

            } minimal: {
                // ── 最小化（多 Activity 时只显示图标）────────────────
                Image(systemName: context.state.isAllCompleted
                      ? "checkmark.circle.fill"
                      : (context.state.hasTasks ? "circle.dotted" : "plus.circle"))
                    .foregroundColor(context.state.isAllCompleted ? .green : .cyan)
            }
            .widgetURL(URL(string: "dailyreflection://today"))
            .keylineTint(context.state.isAllCompleted ? .green : .cyan)
        }
    }
}

// MARK: - 锁屏 Live Activity 视图

@available(iOS 16.2, *)
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<DailyReflectionAttributes>

    var body: some View {
        VStack(spacing: 12) {
            // 顶部：用户名 + 心情
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.cyan).font(.title3)
                Text(context.attributes.username)
                    .font(.headline).fontWeight(.semibold)
                Spacer()
                Label(context.state.mood, systemImage: moodIcon(for: context.state.mood))
                    .font(.caption)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
            }

            if context.state.hasTasks {
                // 当前任务
                VStack(alignment: .leading, spacing: 4) {
                    Text("当前任务").font(.caption).foregroundColor(.secondary)
                    HStack {
                        Image(systemName: context.state.isAllCompleted
                              ? "checkmark.circle.fill" : "circle.dotted")
                            .foregroundColor(context.state.isAllCompleted ? .green : .cyan)
                        Text(context.state.currentTask)
                            .font(.subheadline).fontWeight(.medium).lineLimit(1)
                    }
                    if !context.state.nextTask.isEmpty && !context.state.isAllCompleted {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.right")
                                .font(.caption2).foregroundColor(.secondary)
                            Text("下一个：\(context.state.nextTask)")
                                .font(.caption2).foregroundColor(.secondary).lineLimit(1)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // 进度条
                VStack(spacing: 6) {
                    ProgressView(value: context.state.progress)
                        .progressViewStyle(.linear)
                        .tint(context.state.isAllCompleted ? .green : .cyan)
                    HStack {
                        Text("\(context.state.completedCount)/\(context.state.totalCount) 已完成")
                            .font(.caption).fontWeight(.medium)
                        Spacer()
                        Text(context.state.progressText)
                            .font(.caption).fontWeight(.bold)
                            .foregroundColor(context.state.isAllCompleted ? .green : .cyan)
                        Text("·").foregroundColor(.secondary)
                        Text(context.state.lastUpdate, style: .relative)
                            .font(.caption2).foregroundColor(.secondary)
                    }
                }

                // 锁屏控制按钮（iOS 17+）
                if !context.state.isAllCompleted {
                    HStack(spacing: 10) {
                        Button(intent: PauseTaskIntent()) {
                            HStack(spacing: 5) {
                                Image(systemName: context.state.isTimerRunning
                                      ? "pause.fill" : "play.fill")
                                Text(context.state.isTimerRunning ? "暂停" : "继续")
                                    .fontWeight(.semibold)
                            }
                            .font(.subheadline).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(Color.orange.opacity(0.85),
                                        in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)

                        Button(intent: CompleteTaskIntent()) {
                            HStack(spacing: 5) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("完成").fontWeight(.semibold)
                            }
                            .font(.subheadline).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(Color.cyan.opacity(0.85),
                                        in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2).foregroundColor(.cyan)
                    Text("今日还没有任务，打开 App 添加吧")
                        .font(.subheadline).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .activityBackgroundTint(.cyan.opacity(0.1))
        .activitySystemActionForegroundColor(.cyan)
    }

    private func moodIcon(for mood: String) -> String {
        switch mood {
        case "开心", "快乐", "愉快": return "face.smiling"
        case "平静", "放松", "安宁": return "moon.stars"
        case "疲惫", "疲劳", "困倦": return "powersleep"
        case "焦虑", "紧张", "压力": return "exclamationmark.triangle"
        case "专注", "认真":         return "brain.head.profile"
        default:                     return "face.smiling"
        }
    }
}

// MARK: - 预览
#Preview("进行中", as: .content,
         using: DailyReflectionAttributes(username: "小艺", startTime: Date())) {
    DailyReflectionLiveActivity()
} contentStates: {
    DailyReflectionAttributes.ContentState(
        currentTask: "完成项目文档",
        nextTask: "团队会议",
        isTimerRunning: true,
        completedCount: 2,
        totalCount: 5,
        mood: "专注",
        lastUpdate: Date()
    )
    DailyReflectionAttributes.ContentState(
        currentTask: "全部完成",
        nextTask: "",
        isTimerRunning: false,
        completedCount: 5,
        totalCount: 5,
        mood: "开心",
        lastUpdate: Date()
    )
    DailyReflectionAttributes.ContentState(
        currentTask: "",
        nextTask: "",
        isTimerRunning: false,
        completedCount: 0,
        totalCount: 0,
        mood: "平静",
        lastUpdate: Date()
    )
}