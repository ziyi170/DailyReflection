//
//  MealEntry.swift
//  DailyReflection
//
//  Enhanced model with description field
//

import Foundation

struct MealEntry: Identifiable, Codable {
    var id = UUID()
    var name: String
    var calories: Double
    var mealType: MealType
    var date: Date
    var description: String = ""  // 新增描述字段
    
    enum MealType: String, Codable, CaseIterable {
        case breakfast = "早餐"
        case lunch = "午餐"
        case dinner = "晚餐"
        case snack = "加餐"
    }
}

struct WeightEntry: Identifiable, Codable {
    var id = UUID()
    var weight: Double
    var date: Date
    var note: String
}

extension MealEntry.MealType {
    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "leaf.fill"
        }
    }
}
