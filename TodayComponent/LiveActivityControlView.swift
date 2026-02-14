//
//  LiveActivityControlView.swift
//  DailyReflection
//
//  显示 Live Activity（灵动岛）控制面板
//

import SwiftUI
import ActivityKit

@available(iOS 16.1, *)
struct LiveActivityControlView: View {

    @EnvironmentObject var dataManager: AppDataManager
    @ObservedObject private var activityManager = LiveActivityManager.shared

    @State private var currentMood: String = "平静"

    // 已完成任务数
    private var completedCount: Int {
        dataManager.tasks.filter { $0.isCompleted }.count
    }

    // 下一个未完成任务
    private var nextTask: Task? {
        dataManager.tasks.first(where: { !$0.isCompleted })
    }

    // Live Activity 是否正在运行
    private var isActive: Bool {
        activityManager.currentActivity != nil
    }

    var body: some View {
        VStack(spacing: 12) {

            // MARK: - 标题栏
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(ThemeManager.shared.currentTheme.primaryColor)

                Text("灵动岛")
                    .font(.headline)

                Spacer()

                if isActive {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)

                        Text("运行中")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // MARK: - 状态信息
            if isActive {
                statusInfoView
            }

            // MARK: - 控制按钮
            controlButtons
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal)
    }

    // MARK: - 状态信息视图
    private var statusInfoView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("当前任务")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(nextTask?.title ?? "所有任务已完成")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(completedCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(
                            ThemeManager.shared.currentTheme.primaryColor
                        )

                    Text("/\(dataManager.tasks.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text("已完成")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }

    // MARK: - 控制按钮
    private var controlButtons: some View {
        HStack(spacing: 12) {

            if isActive {

                // 更新
                Button {
                    updateActivity()
                } label: {
                    Label("更新", systemImage: "arrow.clockwise.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(ThemeManager.shared.currentTheme.primaryColor)

                // 停止
                Button {
                    stopActivity()
                } label: {
                    Label("停止", systemImage: "stop.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)

            } else {

                // 启动（实际上是触发一次 update，让 LiveActivityManager 接管）
                Button {
                    startActivity()
                } label: {
                    Label("启动灵动岛", systemImage: "play.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(ThemeManager.shared.currentTheme.primaryColor)
                .disabled(dataManager.tasks.isEmpty)
            }
        }
    }

    // MARK: - Actions

    private func startActivity() {
        // LiveActivityManager 内部如果没有 currentActivity
        // 会在 update 时使用已有 activity 或忽略
        activityManager.update(
            tasks: dataManager.tasks,
            mood: currentMood
        )

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func updateActivity() {
        activityManager.update(
            tasks: dataManager.tasks,
            mood: currentMood
        )

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    private func stopActivity() {
        activityManager.stop()

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
}

// MARK: - iOS 16.0 及以下占位

struct LiveActivityControlPlaceholder: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("灵动岛需要 iOS 16.1 及以上")
            }
            .font(.subheadline)

            Text("升级系统后即可使用此功能")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
    }
}

// MARK: - 包装视图（自动版本判断）

struct LiveActivityControl: View {
    var body: some View {
        if #available(iOS 16.1, *) {
            LiveActivityControlView()
        } else {
            LiveActivityControlPlaceholder()
        }
    }
}

// MARK: - Preview

#Preview {
    LiveActivityControl()
        .environmentObject(AppDataManager.shared)
}
