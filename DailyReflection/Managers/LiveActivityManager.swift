// LiveActivityManager.swift
// 放在 Managers/ 文件夹中
// ✅ 最终修复版：@available(iOS 16.2)，完全消除所有 deprecated 警告

import Foundation
import ActivityKit
import WidgetKit
import Combine

@available(iOS 16.2, *)
class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    
    @Published var currentActivity: Activity<DailyReflectionAttributes>?
    
    private init() {
        checkActiveActivities()
    }
    
    // MARK: - 检查运行中的 Activity
    
    private func checkActiveActivities() {
        for activity in Activity<DailyReflectionAttributes>.activities {
            print("✅ 发现运行中的 Activity: \(activity.id)")
            currentActivity = activity
        }
    }
    
    // MARK: - 启动 Live Activity
    
    func start(tasks: [DailyTask], mood: String, username: String) {
        guard !tasks.isEmpty else {
            print("❌ 无法启动：任务列表为空")
            return
        }

        if let existing = currentActivity {
            Task { await existing.end(dismissalPolicy: .immediate) }
            currentActivity = nil
        }

        let attributes = DailyReflectionAttributes(username: username, startTime: Date())
        let currentTaskTitle = tasks.first(where: { !$0.isCompleted })?.title ?? "所有任务已完成！"
        // ✅ 取第二个未完成任务作为 nextTask
        let pendingTasks = tasks.filter { !$0.isCompleted }
        let nextTaskTitle = pendingTasks.count > 1 ? pendingTasks[1].title : ""
        let completedCount = tasks.filter { $0.isCompleted }.count

        let content = ActivityContent(
            state: DailyReflectionAttributes.ContentState(
                currentTask: currentTaskTitle,
                nextTask: nextTaskTitle,
                isTimerRunning: TimerManager.shared.isRunning,
                completedCount: completedCount,
                totalCount: tasks.count,
                mood: mood,
                lastUpdate: Date()
            ),
            staleDate: nil
        )

        do {
            currentActivity = try Activity.request(
                attributes: attributes, content: content, pushType: nil)
            print("✅ Live Activity 启动成功 | 当前: \(currentTaskTitle) | 下一个: \(nextTaskTitle)")
        } catch {
            print("❌ Live Activity 启动失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 更新 Live Activity
    
    func update(tasks: [DailyTask], mood: String) {
        guard let activity = currentActivity else {
            print("⚠️ 没有活跃的 Activity 可以更新")
            return
        }

        let currentTaskTitle = tasks.first(where: { !$0.isCompleted })?.title ?? "所有任务已完成！"
        let pendingTasks = tasks.filter { !$0.isCompleted }
        let nextTaskTitle = pendingTasks.count > 1 ? pendingTasks[1].title : ""
        let completedCount = tasks.filter { $0.isCompleted }.count

        let content = ActivityContent(
            state: DailyReflectionAttributes.ContentState(
                currentTask: currentTaskTitle,
                nextTask: nextTaskTitle,
                isTimerRunning: TimerManager.shared.isRunning,
                completedCount: completedCount,
                totalCount: tasks.count,
                mood: mood,
                lastUpdate: Date()
            ),
            staleDate: nil
        )

        Task {
            await activity.update(content)
            print("✅ Live Activity 更新 | 当前: \(currentTaskTitle) | 下一个: \(nextTaskTitle)")
        }
    }
    
    // MARK: - 停止 Live Activity
    
    func stop() {
        guard let activity = currentActivity else {
            print("⚠️ 没有活跃的 Activity 可以停止")
            return
        }
        Task {
            await activity.end(dismissalPolicy: .immediate)
            await MainActor.run { currentActivity = nil }
            print("✅ Live Activity 已停止")
        }
    }
    
    // MARK: - 延迟结束（显示完成状态后消失）
    
    func endWithDelay(tasks: [DailyTask], mood: String) {
        guard let activity = currentActivity else { return }
        
        let content = ActivityContent(
            state: DailyReflectionAttributes.ContentState(
                currentTask: "今日任务已完成！🎉",
                completedCount: tasks.filter { $0.isCompleted }.count,
                totalCount: tasks.count,
                mood: mood,
                lastUpdate: Date()
            ),
            staleDate: nil
        )
        
        Task {
            await activity.update(content)
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await activity.end(dismissalPolicy: .default)
            await MainActor.run { currentActivity = nil }
            print("✅ Live Activity 已完成并结束")
        }
    }
    
    // MARK: - 状态查询
    
    var isActive: Bool {
        currentActivity != nil
    }
}