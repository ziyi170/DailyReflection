import Foundation
import WidgetKit

extension AppDataManager {

    static let appGroupID = "group.com.dailyreflection.shared"

    func saveToAppGroup() {
        guard let sharedDefaults = UserDefaults(suiteName: AppDataManager.appGroupID) else {
            print("❌ 无法访问 App Group")
            return
        }

        // ✅ 保存任务（转换成 WidgetTask，避免 Task 冲突）
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

        // 保存当前心情
        if let latestReflection = reflections.sorted(by: { $0.date > $1.date }).first {
            sharedDefaults.set(latestReflection.overallSummary ?? "平静", forKey: "currentMood")
        }

        let username = sharedDefaults.string(forKey: "username") ?? "用户"
        sharedDefaults.set(username, forKey: "username")

        WidgetCenter.shared.reloadAllTimelines()
        print("✅ 数据已保存到 App Group")
    }
}
