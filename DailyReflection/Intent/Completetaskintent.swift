// CompleteTaskIntent.swift
// 放在主 App Target 和 Widget Extension Target 都要勾选
// 让灵动岛可以直接完成当前任务，无需跳转 App

import AppIntents
import WidgetKit

// MARK: - 完成当前任务

struct CompleteTaskIntent: AppIntent {
    static let title: LocalizedStringResource = "完成当前任务"
    static let description = IntentDescription("将当前第一个未完成任务标记为已完成")

    func perform() async throws -> some IntentResult {
        let appGroupID = "group.com.dailyreflection.shared"

        guard let sharedDefaults = UserDefaults(suiteName: appGroupID) else {
            return .result()
        }

        guard let data = sharedDefaults.data(forKey: "tasks"),
              var tasks = try? JSONDecoder().decode([WidgetTask].self, from: data) else {
            return .result()
        }

        // 找到第一个未完成的任务，标记为完成
        guard let index = tasks.firstIndex(where: { !$0.isCompleted }) else {
            return .result() // 没有待完成任务，直接返回
        }

        let old = tasks[index]
        tasks[index] = WidgetTask(
            id: old.id,
            title: old.title,
            date: old.date,
            startTime: old.startTime,
            isCompleted: true
        )

        // 写回 App Group
        if let encoded = try? JSONEncoder().encode(tasks) {
            sharedDefaults.set(encoded, forKey: "tasks")
        }

        // 刷新锁屏 Widget
        WidgetCenter.shared.reloadAllTimelines()

        // 同步更新 Live Activity（如果存在）
        // 注意：Live Activity 的真正状态更新需要主 App 监听
        // 这里通过写入一个信号，让主 App 下次激活时同步
        sharedDefaults.set(true, forKey: "pendingLiveActivityUpdate")

        return .result()
    }
}

// MARK: - 跳转到添加任务页（辅助 Intent，用于灵动岛"添加"按钮）

struct OpenAddTaskIntent: AppIntent {
    static let title: LocalizedStringResource = "添加任务"
    static let description = IntentDescription("打开 App 并进入添加任务页面")
    static let openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}