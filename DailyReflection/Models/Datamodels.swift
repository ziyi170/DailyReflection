//
//  DataModels.swift
//  DailyReflection
//
//  统一完整的数据模型 - 完全兼容所有视图
//

import Foundation
import SwiftUI

// MARK: - 任务模型（完整版）


// MARK: - 白噪音类型

// MARK: - 饮食记录模型


// MARK: - 体重记录模型

// MARK: - DailyReflection（每日复盘模型）
struct DailyReflection: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var overallSummary: String = ""
    var todayLearnings: String = ""
    var tomorrowPlans: String = ""
    var totalRevenue: Double = 0.0
    var totalExpense: Double = 0.0
    var achievements: String = ""       // 新增
    var improvements: String = ""    
    var netIncome: Double {
        totalRevenue - totalExpense
    }
    
    // 完整初始化方法
    init(id: UUID = UUID(),
         date: Date,
         overallSummary: String = "",
         todayLearnings: String = "",
         tomorrowPlans: String = "",
         totalRevenue: Double = 0.0,
         totalExpense: Double = 0.0) {
        self.id = id
        self.date = date
        self.overallSummary = overallSummary
        self.todayLearnings = todayLearnings
        self.tomorrowPlans = tomorrowPlans
        self.totalRevenue = totalRevenue
        self.totalExpense = totalExpense
    }
}

// MARK: - Reflection（旧版复盘模型，保持兼容）
struct Reflection: Identifiable, Codable {
    var id = UUID()
    var content: String = ""
    var date: Date
    var totalRevenue: Double = 0.0
    var totalExpense: Double = 0.0
    var netIncome: Double { totalRevenue - totalExpense }
    
    // 新增字段
    var overallSummary: String = ""
    var todayLearnings: String = ""
    var tomorrowPlans: String = ""
    
    // 完整初始化方法
    init(id: UUID = UUID(),
         content: String = "",
         date: Date,
         totalRevenue: Double = 0.0,
         totalExpense: Double = 0.0,
         overallSummary: String = "",
         todayLearnings: String = "",
         tomorrowPlans: String = "") {
        self.id = id
        self.content = content
        self.date = date
        self.totalRevenue = totalRevenue
        self.totalExpense = totalExpense
        self.overallSummary = overallSummary
        self.todayLearnings = todayLearnings
        self.tomorrowPlans = tomorrowPlans
    }
}

// MARK: - 日历事件模型
struct CalendarEvent: Identifiable {
    var id = UUID()
    var date: Date
    var tasks: [Task]
    var meals: [MealEntry]
    var weight: WeightEntry?
    var reflection: Reflection?
    
    // 计算属性
    var totalCalories: Double {
        meals.reduce(0) { $0 + $1.calories }
    }
    
    var totalRevenue: Double {
        tasks.reduce(0) { $0 + $1.revenue }
    }
    
    var totalExpense: Double {
        tasks.reduce(0) { $0 + $1.expense }
    }
    
    var netIncome: Double {
        totalRevenue - totalExpense
    }
    
    var completedRevenue: Double {
        tasks.filter { $0.isCompleted }.reduce(0) { $0 + $1.revenue }
    }
    
    var completedExpense: Double {
        tasks.filter { $0.isCompleted }.reduce(0) { $0 + $1.expense }
    }
    
    var completedNetIncome: Double {
        completedRevenue - completedExpense
    }
    
    var completedTaskCount: Int {
        tasks.filter { $0.isCompleted }.count
    }
    
    var totalDuration: TimeInterval {
        tasks.reduce(0) { $0 + $1.duration }
    }
    
    var completedDuration: TimeInterval {
        tasks.filter { $0.isCompleted }.reduce(0) { $0 + $1.duration }
    }
}

// MARK: - 白噪音管理器

// MARK: - 应用数据管理器（完整版）

    
    // MARK: - 数据持久化
    
    
    
    // MARK: - 获取日历事件
    


// MARK: - 扩展：日期工具
extension Date {
    func startOfDay() -> Date {
        Calendar.current.startOfDay(for: self)
    }
    
    func endOfDay() -> Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay())!
    }
    
    func isToday() -> Bool {
        Calendar.current.isDateInToday(self)
    }
    
    func isSameDay(as date: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: date)
    }
}

// MARK: - 示例数据
extension AppDataManager {
    func loadSampleData() {
        let today = Date()
        let calendar = Calendar.current
        
        // 示例任务
        
          
        
        // 示例饮食
        meals = [
            MealEntry(
                name: "燕麦粥",
                calories: 150,
                mealType: .breakfast,
                date: today,
                description: "250克"
            ),
            MealEntry(
                name: "鸡胸肉沙拉",
                calories: 350,
                mealType: .lunch,
                date: today,
                description: "一份"
            )
        ]
        
        // 示例体重
        weights = [
            WeightEntry(
                weight: 70.5,
                date: today,
                note: "感觉不错"
            )
        ]
        
        saveAllData()
    }
}
