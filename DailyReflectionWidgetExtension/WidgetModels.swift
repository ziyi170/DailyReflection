// [file name]: WidgetModels.swift
// [file content begin]
//
//  WidgetModels.swift
//  DailyReflectionWidgetExtension
//
//  共享数据模型和提供者
//

import WidgetKit
import SwiftUI

// MARK: - Widget 专用 Task 模型（避免与 Swift 并发 Task 冲突）
struct WidgetTask: Identifiable, Codable {
    let id: UUID
    let title: String
    let date: Date
    let startTime: Date
    let isCompleted: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, title, date, startTime, isCompleted
    }
}

// MARK: - Timeline Entry
struct TaskEntry: TimelineEntry {
    let date: Date
    let tasks: [WidgetTask]
    let completedCount: Int
    let mood: String
    let username: String
}

// MARK: - Timeline Provider
struct TaskProvider: TimelineProvider {
    func placeholder(in context: Context) -> TaskEntry {
        TaskEntry(
            date: Date(),
            tasks: [],
            completedCount: 0,
            mood: "平静",
            username: "用户"
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TaskEntry) -> ()) {
        let tasks = loadTasks()
        let entry = TaskEntry(
            date: Date(),
            tasks: tasks,
            completedCount: tasks.filter { $0.isCompleted }.count,
            mood: loadMood(),
            username: loadUsername()
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskEntry>) -> ()) {
        let currentDate = Date()
        let tasks = loadTasks()
        
        let entry = TaskEntry(
            date: currentDate,
            tasks: tasks,
            completedCount: tasks.filter { $0.isCompleted }.count,
            mood: loadMood(),
            username: loadUsername()
        )
        
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
    
    // MARK: - 数据加载（从 App Group 读）
    private func loadTasks() -> [WidgetTask] {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.dailyreflection.shared"),
              let data = sharedDefaults.data(forKey: "tasks"),
              let tasks = try? JSONDecoder().decode([WidgetTask].self, from: data) else {
            return []
        }
        
        let today = Calendar.current.startOfDay(for: Date())
        
        return tasks
            .filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
            .sorted { t1, t2 in
                if t1.isCompleted != t2.isCompleted {
                    return !t1.isCompleted
                }
                return t1.startTime < t2.startTime
            }
    }
    
    private func loadMood() -> String {
        UserDefaults(suiteName: "group.com.dailyreflection.shared")?
            .string(forKey: "currentMood") ?? "平静"
    }
    
    private func loadUsername() -> String {
        UserDefaults(suiteName: "group.com.dailyreflection.shared")?
            .string(forKey: "username") ?? "用户"
    }
}

// MARK: - Widget Background
extension View {
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOS 17.0, *) {
            return containerBackground(for: .widget) {
                color
            }
        } else {
            return background(color)
        }
    }
}
// [file content end]//
//  WidgetModels.swift
//  DailyReflection
//
//  Created by 小艺 on 2026/2/5.
//

