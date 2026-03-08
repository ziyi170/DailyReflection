// AppDataManager+Widget.swift
// ✅ 修复：username 正确保存、监听 pendingLiveActivityUpdate 信号同步 Live Activity

import Foundation
import WidgetKit

extension AppDataManager {

    static let appGroupID = "group.com.dailyreflection.shared"

    // MARK: - 保存数据到 App Group（Widget 读取用）

    func saveToAppGroup() {
        guard let sharedDefaults = UserDefaults(suiteName: AppDataManager.appGroupID) else {
            print("❌ 无法访问 App Group，请确认 Xcode 已开启 App Groups Capability")
            return
        }

        // ✅ 保存任务（转换为 WidgetTask，避免与 Swift 并发 Task 冲突）
        let widgetTasks: [WidgetTask] = tasks.map {
            WidgetTask(
                id: $0.id,
                title: $0.title,
                date: $0.date,
                startTime: $0.startTime,
                isCompleted: $0.isCompleted
            )
        }

        if let tasksData = try? JSONEncoder().encode(widgetTasks) {
            sharedDefaults.set(tasksData, forKey: "tasks")
        }

        // 保存饮食记录
        if let mealsData = try? JSONEncoder().encode(meals) {
            sharedDefaults.set(mealsData, forKey: "meals")
        }

        // ✅ 保存当前心情（优先取最新 reflection，否则保留已有值）
        let mood = getCurrentMood()
        sharedDefaults.set(mood, forKey: "currentMood")

        // ✅ 修复：username 从主 App UserDefaults 读取（你设置用户名的 key 改成你自己的）
        // 如果你在主 App 里用不同的 key 存了用户名，把 "username" 改成对应 key
        let username = UserDefaults.standard.string(forKey: "username")
                    ?? sharedDefaults.string(forKey: "username")
                    ?? "用户"
        sharedDefaults.set(username, forKey: "username")

        // 刷新所有 Widget
        WidgetCenter.shared.reloadAllTimelines()
        print("✅ App Group 数据已同步 | 任务数: \(widgetTasks.count) | 心情: \(mood) | 用户: \(username)")
    }

    // MARK: - 从 App Group 读取（启动时校验用）

    func loadFromAppGroup() {
        guard let sharedDefaults = UserDefaults(suiteName: AppDataManager.appGroupID) else { return }

        if let data = sharedDefaults.data(forKey: "tasks"),
           let decoded = try? JSONDecoder().decode([WidgetTask].self, from: data) {
            print("✅ App Group 中有 \(decoded.count) 个任务")
        } else {
            print("⚠️ App Group 中暂无任务数据，将在首次保存后写入")
        }
    }

    // MARK: - 处理 CompleteTaskIntent 写回的完成信号
    // 在 App 进入前台时调用此方法，将 Widget/灵动岛完成的任务同步回主 App

    func syncCompletedTasksFromWidget() {
        guard let sharedDefaults = UserDefaults(suiteName: AppDataManager.appGroupID) else { return }

        // 检查是否有待同步的更新
        let hasPending = sharedDefaults.bool(forKey: "pendingLiveActivityUpdate")
        guard hasPending else { return }

        // 读取 Widget 侧已修改的任务列表
        guard let data = sharedDefaults.data(forKey: "tasks"),
              let widgetTasks = try? JSONDecoder().decode([WidgetTask].self, from: data) else { return }

        // 将 Widget 中已标为完成的任务同步回主 App tasks
        var changed = false
        for widgetTask in widgetTasks where widgetTask.isCompleted {
            if let index = tasks.firstIndex(where: { $0.id == widgetTask.id && !$0.isCompleted }) {
                tasks[index].isCompleted = true
                changed = true
                print("✅ 从 Widget 同步完成任务: \(tasks[index].title)")
            }
        }

        if changed {
            saveData() // 写回主 App UserDefaults
            // 重置待同步标记
            sharedDefaults.set(false, forKey: "pendingLiveActivityUpdate")

            // 更新 Live Activity 状态
            if #available(iOS 16.2, *) {
                let mood = getCurrentMood()
                LiveActivityManager.shared.update(tasks: tasks, mood: mood)

                // 如果全部完成，延迟结束 Live Activity
                if tasks.allSatisfy({ $0.isCompleted }) {
                    LiveActivityManager.shared.endWithDelay(tasks: tasks, mood: mood)
                }
            }
        }
    }
}