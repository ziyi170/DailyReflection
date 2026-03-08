import Foundation
import Combine

final class AppDataManager: ObservableObject {
    static let shared = AppDataManager()

    public init() {
        loadData()
        loadFromAppGroup()
    }

    @Published var dailyReflections: [DailyReflection] = []
    @Published var tasks: [DailyTask] = []
    @Published var meals: [MealEntry] = []
    @Published var weights: [WeightEntry] = []
    @Published var reflections: [Reflection] = []

    // MARK: - Calendar Page Data

    func getEventsForDate(_ date: Date) -> CalendarEvent {
        let calendar = Calendar.current

        let dayTasks = tasks.filter { calendar.isDate($0.date, inSameDayAs: date) }
        let dayMeals = meals.filter { calendar.isDate($0.date, inSameDayAs: date) }
        let dayWeight = weights.first { calendar.isDate($0.date, inSameDayAs: date) }
        let dayReflection = reflections.first { calendar.isDate($0.date, inSameDayAs: date) }
        let dayDailyReflection = dailyReflections.first { calendar.isDate($0.date, inSameDayAs: date) }

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

    // MARK: - CRUD Tasks

    func addTask(_ task: DailyTask) {
        // ✅ 修复：去掉 newTask.calendarEventId = eventId 赋值
        //    CalendarSyncManager.addTaskToCalendar 内部已直接写入 UserDefaults
        //    calendarEventId 是只读 computed property，通过 UserDefaults getter 读取
        if CalendarSyncManager.shared.isCalendarSyncEnabled {
            _ = CalendarSyncManager.shared.addTaskToCalendar(task)
        }

        tasks.append(task)
        saveAllData()
        saveToAppGroup()

        if #available(iOS 16.2, *) {
            updateLiveActivity()
        }
    }

    func updateTask(_ task: DailyTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            saveAllData()
            saveToAppGroup()

            if #available(iOS 16.2, *) {
                updateLiveActivity()
            }
        }
    }

    func deleteTask(_ task: DailyTask) {
        tasks.removeAll { $0.id == task.id }
        saveAllData()
        saveToAppGroup()

        if #available(iOS 16.2, *) {
            updateLiveActivity()
        }
    }

    func deleteTaskAndSync(_ task: DailyTask) {
        if let eventId = task.calendarEventId {
            CalendarSyncManager.shared.deleteTaskFromCalendar(eventId: eventId)
        }
        deleteTask(task)
    }

    func toggleTaskCompletion(_ task: DailyTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            saveAllData()
            saveToAppGroup()

            if #available(iOS 16.2, *) {
                updateLiveActivity()
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
        saveToAppGroup()
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
    }

    func loadData() {
        if let data = UserDefaults.standard.data(forKey: "tasks"),
           let decoded = try? JSONDecoder().decode([DailyTask].self, from: data) {
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
    @available(iOS 16.2, *)
    func updateLiveActivity() {
        let mood = getCurrentMood()
        LiveActivityManager.shared.update(tasks: tasks, mood: mood)
    }

    func getCurrentMood() -> String {
        if let latestReflection = reflections.max(by: { $0.date < $1.date }),
           !latestReflection.overallSummary.isEmpty {
            return latestReflection.overallSummary
        }
        if let sharedDefaults = UserDefaults(suiteName: AppDataManager.appGroupID),
           let savedMood = sharedDefaults.string(forKey: "currentMood"),
           !savedMood.isEmpty {
            return savedMood
        }
        return "平静"
    }
}