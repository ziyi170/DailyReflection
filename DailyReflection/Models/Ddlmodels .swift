//
//  Ddlmodels.swift
//  DailyReflection
//
//  Created by 小艺 on 2026/2/17.
//
import Foundation

// MARK: - DDL 项目数据模型
struct DDLProject: Identifiable, Codable, NotifiableTask {
    let id: UUID
    var title: String
    var deadline: Date
    var notes: String
    var reminderSettings: [ReminderSetting]
    var isCompleted: Bool
    
    init(id: UUID = UUID(), title: String, deadline: Date, notes: String = "", reminderSettings: [ReminderSetting] = [], isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.deadline = deadline
        self.notes = notes
        self.reminderSettings = reminderSettings
        self.isCompleted = isCompleted
    }
    
    var timeRemaining: String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour, .minute], from: now, to: deadline)
        
        if let days = components.day, days > 0 {
            return "还有\(days)天"
        } else if let hours = components.hour, hours > 0 {
            return "还有\(hours)小时"
        } else if let minutes = components.minute, minutes > 0 {
            return "还有\(minutes)分钟"
        } else {
            return "已截止"
        }
    }
    
    // ✅ NotifiableTask 协议：startTime 用于任务开始通知，deadlineDate 用于截止提醒
    var startTime: Date { deadline }
    var deadlineDate: Date? { deadline }

    var isOverdue: Bool {
        deadline < Date()
    }
}

// MARK: - 提醒设置
struct ReminderSetting: Codable, Identifiable {
    let id: UUID
    var type: ReminderType
    var customDays: Int?
    
    init(id: UUID = UUID(), type: ReminderType, customDays: Int? = nil) {
        self.id = id
        self.type = type
        self.customDays = customDays
    }
    
    enum ReminderType: String, Codable {
        case oneHourBefore = "1小时前"
        case oneDayBefore = "1天前"
        case threeDaysBefore = "3天前"
        case oneWeekBefore = "1周前"
        case custom = "自定义"
    }
}