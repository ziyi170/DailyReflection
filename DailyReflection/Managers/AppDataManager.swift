import Foundation
import Combine
// [file name]: AppDataManager.swift
// 在文件末尾添加 App Group 相关扩展

extension AppDataManager {
    // MARK: - App Group 常量
    
    
    // MARK: - App Group 数据同步（Widget 使用）
    
    /// 保存数据到 App Group（供 Widget 使用）
    
        
       
    
    /// 从 App Group 加载数据
    func loadFromAppGroup() {
        guard let sharedDefaults = UserDefaults(suiteName: AppDataManager.appGroupID) else {
            print("❌ 无法访问 App Group")
            return
        }
        
        // 注意：AppDataManager 本身从本地 UserDefaults 加载数据
        // 这个方法主要是为了初始化时确保 App Group 有数据
        if let encodedTasks = sharedDefaults.data(forKey: "tasks"),
           let decodedTasks = try? JSONDecoder().decode([Task].self, from: encodedTasks) {
            // 可以选择性地合并数据，这里我们以本地为主
            print("✅ 从 App Group 加载了 \(decodedTasks.count) 个任务")
        }
    }
}

final class AppDataManager: ObservableObject {
    static let shared = AppDataManager()

    public init() {
        loadData()          // 本地数据
        loadFromAppGroup()  // AppGroup 数据（Widget）
    }

    @Published var dailyReflections: [DailyReflection] = []
    @Published var tasks: [Task] = []
    @Published var meals: [MealEntry] = []
    @Published var weights: [WeightEntry] = []
    @Published var reflections: [Reflection] = []

    // MARK: - Calendar Page Data

    func getEventsForDate(_ date: Date) -> CalendarEvent {
        let calendar = Calendar.current

        let dayTasks = tasks.filter { task in
            calendar.isDate(task.date, inSameDayAs: date)
        }

        let dayMeals = meals.filter { meal in
            calendar.isDate(meal.date, inSameDayAs: date)
        }

        let dayWeight = weights.first { weight in
            calendar.isDate(weight.date, inSameDayAs: date)
        }

        let dayReflection = reflections.first { reflection in
            calendar.isDate(reflection.date, inSameDayAs: date)
        }

        let dayDailyReflection = dailyReflections.first { reflection in
            calendar.isDate(reflection.date, inSameDayAs: date)
        }

        var combinedReflection = dayReflection
        if let daily = dayDailyReflection {
            if combinedReflection == nil {
                combinedReflection = Reflection(
                    id: daily.id,
                    content: daily.overallSummary,
                    date: daily.date,
                    totalRevenue: daily.totalRevenue,
                    overallSummary: daily.overallSummary,
                    todayLearnings: daily.todayLearnings,
                    tomorrowPlans: daily.tomorrowPlans
                )
            } else {
                combinedReflection?.overallSummary = daily.overallSummary
                combinedReflection?.todayLearnings = daily.todayLearnings
                combinedReflection?.tomorrowPlans = daily.tomorrowPlans
            }
        }

        return CalendarEvent(
            date: date,
            tasks: dayTasks,
            meals: dayMeals,
            weight: dayWeight,
            reflection: combinedReflection
        )
    }

    // MARK: - CRUD Tasks (统一入口)

    /// ✅ 添加任务：保存 + AppGroup + LiveActivity + 日历同步
    func addTask(_ task: Task) {
        var newTask = task

        // 🆕 同步到日历（先同步再保存 eventId）
        if CalendarSyncManager.shared.isCalendarSyncEnabled {
            if let eventId = CalendarSyncManager.shared.addTaskToCalendar(newTask) {
                newTask.calendarEventId = eventId
            }
        }

        tasks.append(newTask)

        saveAllData()
        saveToAppGroup()

        // 更新 Live Activity
        if #available(iOS 16.1, *) {
            updateLiveActivity()
        }
    }

    /// 更新任务并同步
    func updateTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task

            saveAllData()
            saveToAppGroup()

            if #available(iOS 16.1, *) {
                updateLiveActivity()
            }
        }
    }

    /// 删除任务（基础）
    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        saveAllData()
        saveToAppGroup()

        if #available(iOS 16.1, *) {
            updateLiveActivity()
        }
    }
    
    func deleteTaskAndSync(_ task: Task) {
        // 从日历删除
        if let eventId = task.calendarEventId {
            CalendarSyncManager.shared.deleteTaskFromCalendar(eventId: eventId)
        }
        
        // 从数据中删除
        deleteTask(task)
    }

    /// 切换完成状态
    func toggleTaskCompletion(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()

            saveAllData()
            saveToAppGroup()

            if #available(iOS 16.1, *) {
                updateLiveActivity()

                // 如果全部完成，结束 Live Activity（可选）
                if tasks.allSatisfy({ $0.isCompleted }) {
                    let mood = getCurrentMood()
                    LiveActivityManager.shared.endWithDelay(tasks: tasks, mood: mood)
                }
            }
        }
    }

    // MARK: - Save / Load

    func saveAllData() {
        saveData()
    }

    func saveData() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: "tasks")
        }
        if let encoded = try? JSONEncoder().encode(meals) {
            UserDefaults.standard.set(encoded, forKey: "meals")
        }
        if let encoded = try? JSONEncoder().encode(weights) {
            UserDefaults.standard.set(encoded, forKey: "weights")
        }
        if let encoded = try? JSONEncoder().encode(reflections) {
            UserDefaults.standard.set(encoded, forKey: "reflections")
        }
        if let encoded = try? JSONEncoder().encode(dailyReflections) {
            UserDefaults.standard.set(encoded, forKey: "dailyReflections")
        }

        // ✅ 每次保存本地也同步到 AppGroup
        saveToAppGroup()
    }

    func loadData() {
        if let data = UserDefaults.standard.data(forKey: "tasks"),
           let decoded = try? JSONDecoder().decode([Task].self, from: data) {
            tasks = decoded
        }

        if let data = UserDefaults.standard.data(forKey: "meals"),
           let decoded = try? JSONDecoder().decode([MealEntry].self, from: data) {
            meals = decoded
        }

        if let data = UserDefaults.standard.data(forKey: "weights"),
           let decoded = try? JSONDecoder().decode([WeightEntry].self, from: data) {
            weights = decoded
        }

        if let data = UserDefaults.standard.data(forKey: "reflections"),
           let decoded = try? JSONDecoder().decode([Reflection].self, from: data) {
            reflections = decoded
        }

        if let data = UserDefaults.standard.data(forKey: "dailyReflections"),
           let decoded = try? JSONDecoder().decode([DailyReflection].self, from: data) {
            dailyReflections = decoded
        }
    }
}

// MARK: - Live Activity Helper

extension AppDataManager {
    @available(iOS 16.1, *)
    fileprivate func updateLiveActivity() {
        let mood = getCurrentMood()
        LiveActivityManager.shared.update(tasks: tasks, mood: mood)
    }

    fileprivate func getCurrentMood() -> String {
        // 1) 最新 reflection
        if let latestReflection = reflections.max(by: { $0.date < $1.date }),
           !latestReflection.overallSummary.isEmpty {
            return latestReflection.overallSummary
        }

        // 2) AppGroup 兜底
        if let sharedDefaults = UserDefaults(suiteName: AppDataManager.appGroupID),
           let savedMood = sharedDefaults.string(forKey: "currentMood"),
           !savedMood.isEmpty {
            return savedMood
        }

        return "平静"
    }
}
