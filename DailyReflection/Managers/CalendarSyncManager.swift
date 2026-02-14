// CalendarSyncManager.swift
// iOS 日历和提醒事项同步管理器
// 放在 Managers/ 文件夹中

import Foundation
import EventKit
import Combine
import UIKit

class CalendarSyncManager: ObservableObject {
    static let shared = CalendarSyncManager()
    
    private let eventStore = EKEventStore()
    
    @Published var isCalendarSyncEnabled = false
    @Published var isRemindersSyncEnabled = false
    @Published var calendarAuthStatus: EKAuthorizationStatus = .notDetermined
    @Published var remindersAuthStatus: EKAuthorizationStatus = .notDetermined
    
    // 日历相关
    private var defaultCalendar: EKCalendar?
    private let calendarIdentifier = "com.dailyreflection.calendar"
    
    // 提醒事项相关
    private var defaultReminderList: EKCalendar?
    private let reminderListIdentifier = "com.dailyreflection.reminders"
    
    init() {
        loadSyncSettings()
        checkAuthorizationStatus()
    }
    
    // MARK: - 权限管理
    
    func checkAuthorizationStatus() {
        if #available(iOS 17.0, *) {
            calendarAuthStatus = EKEventStore.authorizationStatus(for: .event)
            remindersAuthStatus = EKEventStore.authorizationStatus(for: .reminder)
        } else {
            calendarAuthStatus = EKEventStore.authorizationStatus(for: .event)
            remindersAuthStatus = EKEventStore.authorizationStatus(for: .reminder)
        }
    }
    
    /// 请求日历权限
    func requestCalendarAccess(completion: @escaping (Bool, Error?) -> Void) {
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { granted, error in
                DispatchQueue.main.async {
                    self.calendarAuthStatus = granted ? .fullAccess : .denied
                    if granted {
                        self.setupDefaultCalendar()
                    }
                    completion(granted, error)
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, error in
                DispatchQueue.main.async {
                    self.calendarAuthStatus = granted ? .authorized : .denied
                    if granted {
                        self.setupDefaultCalendar()
                    }
                    completion(granted, error)
                }
            }
        }
    }
    
    /// 请求提醒事项权限
    func requestRemindersAccess(completion: @escaping (Bool, Error?) -> Void) {
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToReminders { granted, error in
                DispatchQueue.main.async {
                    self.remindersAuthStatus = granted ? .fullAccess : .denied
                    if granted {
                        self.setupDefaultReminderList()
                    }
                    completion(granted, error)
                }
            }
        } else {
            eventStore.requestAccess(to: .reminder) { granted, error in
                DispatchQueue.main.async {
                    self.remindersAuthStatus = granted ? .authorized : .denied
                    if granted {
                        self.setupDefaultReminderList()
                    }
                    completion(granted, error)
                }
            }
        }
    }
    
    // MARK: - 日历设置
    
    private func setupDefaultCalendar() {
        // 查找或创建"每日反思"日历
        if let existingCalendar = eventStore.calendars(for: .event).first(where: { $0.title == "每日反思" }) {
            defaultCalendar = existingCalendar
        } else {
            let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
            newCalendar.title = "每日反思"
            newCalendar.cgColor = UIColor.systemBlue.cgColor
            newCalendar.source = eventStore.defaultCalendarForNewEvents?.source
            
            do {
                try eventStore.saveCalendar(newCalendar, commit: true)
                defaultCalendar = newCalendar
                print("✅ 创建日历成功")
            } catch {
                print("❌ 创建日历失败: \(error)")
            }
        }
    }
    
    private func setupDefaultReminderList() {
        // 查找或创建"每日反思 DDL"提醒列表
        if let existingList = eventStore.calendars(for: .reminder).first(where: { $0.title == "每日反思 DDL" }) {
            defaultReminderList = existingList
        } else {
            let newList = EKCalendar(for: .reminder, eventStore: eventStore)
            newList.title = "每日反思 DDL"
            newList.cgColor = UIColor.systemRed.cgColor
            newList.source = eventStore.defaultCalendarForNewReminders()?.source
            
            do {
                try eventStore.saveCalendar(newList, commit: true)
                defaultReminderList = newList
                print("✅ 创建提醒列表成功")
            } catch {
                print("❌ 创建提醒列表失败: \(error)")
            }
        }
    }
    
    // MARK: - 任务同步到日历
    
    /// 将任务添加到 iOS 日历
    func addTaskToCalendar(_ task: Task) -> String? {
        guard isCalendarSyncEnabled, let calendar = defaultCalendar else {
            return nil
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = task.title
        event.startDate = task.startTime
        event.endDate = task.endTime
        event.notes = task.notes
        event.calendar = calendar
        
        // 添加分类为位置
        if !task.category.isEmpty {
            event.location = task.category
        }
        
        do {
            try eventStore.save(event, span: .thisEvent)
            print("✅ 任务已同步到日历: \(task.title)")
            return event.eventIdentifier
        } catch {
            print("❌ 同步到日历失败: \(error)")
            return nil
        }
    }
    
    /// 更新日历中的任务
    func updateTaskInCalendar(eventId: String, task: Task) {
        guard isCalendarSyncEnabled else { return }
        
        if let event = eventStore.event(withIdentifier: eventId) {
            event.title = task.title
            event.startDate = task.startTime
            event.endDate = task.endTime
            event.notes = task.notes
            event.location = task.category
            
            do {
                try eventStore.save(event, span: .thisEvent)
                print("✅ 日历事件已更新: \(task.title)")
            } catch {
                print("❌ 更新日历事件失败: \(error)")
            }
        }
    }
    
    /// 从日历中删除任务
    func deleteTaskFromCalendar(eventId: String) {
        guard isCalendarSyncEnabled else { return }
        
        if let event = eventStore.event(withIdentifier: eventId) {
            do {
                try eventStore.remove(event, span: .thisEvent)
                print("✅ 已从日历删除任务")
            } catch {
                print("❌ 从日历删除失败: \(error)")
            }
        }
    }
    
    // MARK: - DDL 同步到提醒事项
    
    /// 将 DDL 添加到提醒事项
    func addDDLToReminders(_ ddl: DDLProject) -> String? {
        guard isRemindersSyncEnabled, let reminderList = defaultReminderList else {
            return nil
        }
        
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = ddl.title
        reminder.notes = ddl.notes
        reminder.calendar = reminderList
        
        // 设置截止日期
        let dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: ddl.deadline)
        reminder.dueDateComponents = dueDateComponents
        
        // 添加提醒
        for reminderSetting in ddl.reminderSettings {
            addAlarmToReminder(reminder, setting: reminderSetting, deadline: ddl.deadline)
        }
        
        do {
            try eventStore.save(reminder, commit: true)
            print("✅ DDL 已同步到提醒事项: \(ddl.title)")
            return reminder.calendarItemIdentifier
        } catch {
            print("❌ 同步到提醒事项失败: \(error)")
            return nil
        }
    }
    
    /// 更新提醒事项中的 DDL
    func updateDDLInReminders(reminderId: String, ddl: DDLProject) {
        guard isRemindersSyncEnabled else { return }
        
        if let reminder = eventStore.calendarItem(withIdentifier: reminderId) as? EKReminder {
            reminder.title = ddl.title
            reminder.notes = ddl.notes
            
            let dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: ddl.deadline)
            reminder.dueDateComponents = dueDateComponents
            
            // 更新完成状态
            reminder.isCompleted = ddl.isCompleted
            if ddl.isCompleted {
                reminder.completionDate = Date()
            }
            
            // 清除旧的提醒，添加新的
            reminder.alarms?.removeAll()
            for reminderSetting in ddl.reminderSettings {
                addAlarmToReminder(reminder, setting: reminderSetting, deadline: ddl.deadline)
            }
            
            do {
                try eventStore.save(reminder, commit: true)
                print("✅ 提醒事项已更新: \(ddl.title)")
            } catch {
                print("❌ 更新提醒事项失败: \(error)")
            }
        }
    }
    
    /// 从提醒事项中删除 DDL
    func deleteDDLFromReminders(reminderId: String) {
        guard isRemindersSyncEnabled else { return }
        
        if let reminder = eventStore.calendarItem(withIdentifier: reminderId) as? EKReminder {
            do {
                try eventStore.remove(reminder, commit: true)
                print("✅ 已从提醒事项删除 DDL")
            } catch {
                print("❌ 从提醒事项删除失败: \(error)")
            }
        }
    }
    
    private func addAlarmToReminder(_ reminder: EKReminder, setting: ReminderSetting, deadline: Date) {
        var timeInterval: TimeInterval = 0
        
        switch setting.type {
        case .oneHourBefore:
            timeInterval = -3600 // 1小时前
        case .oneDayBefore:
            timeInterval = -86400 // 1天前
        case .threeDaysBefore:
            timeInterval = -259200 // 3天前
        case .oneWeekBefore:
            timeInterval = -604800 // 7天前
        case .custom:
            if let days = setting.customDays {
                timeInterval = -Double(days * 86400)
            }
        }
        
        let alarmDate = deadline.addingTimeInterval(timeInterval)
        let alarm = EKAlarm(absoluteDate: alarmDate)
        reminder.addAlarm(alarm)
    }
    
    // MARK: - 同步设置
    
    func toggleCalendarSync(enabled: Bool, completion: @escaping (Bool) -> Void) {
        if enabled {
            // 检查权限
            if calendarAuthStatus == .authorized || calendarAuthStatus == .fullAccess {
                isCalendarSyncEnabled = true
                saveSyncSettings()
                completion(true)
            } else {
                // 请求权限
                requestCalendarAccess { granted, _ in
                    if granted {
                        self.isCalendarSyncEnabled = true
                        self.saveSyncSettings()
                    }
                    completion(granted)
                }
            }
        } else {
            isCalendarSyncEnabled = false
            saveSyncSettings()
            completion(true)
        }
    }
    
    func toggleRemindersSync(enabled: Bool, completion: @escaping (Bool) -> Void) {
        if enabled {
            if remindersAuthStatus == .authorized || remindersAuthStatus == .fullAccess {
                isRemindersSyncEnabled = true
                saveSyncSettings()
                completion(true)
            } else {
                requestRemindersAccess { granted, _ in
                    if granted {
                        self.isRemindersSyncEnabled = true
                        self.saveSyncSettings()
                    }
                    completion(granted)
                }
            }
        } else {
            isRemindersSyncEnabled = false
            saveSyncSettings()
            completion(true)
        }
    }
    
    private func saveSyncSettings() {
        UserDefaults.standard.set(isCalendarSyncEnabled, forKey: "isCalendarSyncEnabled")
        UserDefaults.standard.set(isRemindersSyncEnabled, forKey: "isRemindersSyncEnabled")
    }
    
    private func loadSyncSettings() {
        isCalendarSyncEnabled = UserDefaults.standard.bool(forKey: "isCalendarSyncEnabled")
        isRemindersSyncEnabled = UserDefaults.standard.bool(forKey: "isRemindersSyncEnabled")
    }
    
    // MARK: - 批量同步
    
    /// 同步所有任务到日历
    func syncAllTasksToCalendar(_ tasks: [Task]) {
        guard isCalendarSyncEnabled else { return }
        
        for task in tasks {
            _ = addTaskToCalendar(task)
        }
    }
    
    /// 同步所有 DDL 到提醒事项
    func syncAllDDLsToReminders(_ ddls: [DDLProject]) {
        guard isRemindersSyncEnabled else { return }
        
        for ddl in ddls {
            _ = addDDLToReminders(ddl)
        }
    }
}

// MARK: - Task 扩展（添加日历 ID）

extension Task {
    var calendarEventId: String? {
        get {
            // 从 UserDefaults 或其他存储中获取
            UserDefaults.standard.string(forKey: "calendarEventId_\(id.uuidString)")
        }
        set {
            if let newValue = newValue {
                UserDefaults.standard.set(newValue, forKey: "calendarEventId_\(id.uuidString)")
            } else {
                UserDefaults.standard.removeObject(forKey: "calendarEventId_\(id.uuidString)")
            }
        }
    }
}

// MARK: - DDLProject 扩展（添加提醒 ID）

extension DDLProject {
    var reminderItemId: String? {
        get {
            UserDefaults.standard.string(forKey: "reminderItemId_\(id.uuidString)")
        }
        set {
            if let newValue = newValue {
                UserDefaults.standard.set(newValue, forKey: "reminderItemId_\(id.uuidString)")
            } else {
                UserDefaults.standard.removeObject(forKey: "reminderItemId_\(id.uuidString)")
            }
        }
    }
}
