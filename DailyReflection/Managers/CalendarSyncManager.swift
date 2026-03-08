// CalendarSyncManager.swift
// iOS 日历和提醒事项同步管理器
// ✅ 最终修复版：消除所有 deprecated 和 Sendable 警告

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

    private var defaultCalendar: EKCalendar?
    private let calendarIdentifier = "com.dailyreflection.calendar"

    private var defaultReminderList: EKCalendar?
    private let reminderListIdentifier = "com.dailyreflection.reminders"

    init() {
        loadSyncSettings()
        checkAuthorizationStatus()
    }

    // MARK: - 权限管理

    func checkAuthorizationStatus() {
        calendarAuthStatus = EKEventStore.authorizationStatus(for: .event)
        remindersAuthStatus = EKEventStore.authorizationStatus(for: .reminder)

        if isCalendarGranted && isCalendarSyncEnabled {
            setupDefaultCalendar()
        }
        if isRemindersGranted && isRemindersSyncEnabled {
            setupDefaultReminderList()
        }
    }

    // ✅ 修复1：去掉 .authorized，iOS 17+ 只使用 .fullAccess / .writeOnly
    private var isCalendarGranted: Bool {
        if #available(iOS 17.0, *) {
            return calendarAuthStatus == .fullAccess ||
                   calendarAuthStatus == .writeOnly
        } else {
            return calendarAuthStatus == .authorized
        }
    }

    private var isRemindersGranted: Bool {
        if #available(iOS 17.0, *) {
            return remindersAuthStatus == .fullAccess
        } else {
            return remindersAuthStatus == .authorized
        }
    }

    // ✅ 修复2：用 @Sendable 标注 completion，消除 non-Sendable closure 警告
    func requestCalendarAccess(completion: @escaping @Sendable (Bool, (any Error)?) -> Void) {
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { granted, error in
                DispatchQueue.main.async {
                    self.calendarAuthStatus = granted ? .fullAccess : .denied
                    if granted { self.setupDefaultCalendar() }
                    completion(granted, error)
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, error in
                DispatchQueue.main.async {
                    self.calendarAuthStatus = granted ? .authorized : .denied
                    if granted { self.setupDefaultCalendar() }
                    completion(granted, error)
                }
            }
        }
    }

    func requestRemindersAccess(completion: @escaping @Sendable (Bool, (any Error)?) -> Void) {
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToReminders { granted, error in
                DispatchQueue.main.async {
                    self.remindersAuthStatus = granted ? .fullAccess : .denied
                    if granted { self.setupDefaultReminderList() }
                    completion(granted, error)
                }
            }
        } else {
            eventStore.requestAccess(to: .reminder) { granted, error in
                DispatchQueue.main.async {
                    self.remindersAuthStatus = granted ? .authorized : .denied
                    if granted { self.setupDefaultReminderList() }
                    completion(granted, error)
                }
            }
        }
    }

    // MARK: - 日历设置

    private func setupDefaultCalendar() {
        if let existing = eventStore.calendars(for: .event).first(where: { $0.title == "每日反思" }) {
            defaultCalendar = existing
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
        if let existing = eventStore.calendars(for: .reminder).first(where: { $0.title == "每日反思 DDL" }) {
            defaultReminderList = existing
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

    func addTaskToCalendar(_ task: DailyTask) -> String? {
        guard isCalendarSyncEnabled, let calendar = defaultCalendar else { return nil }

        let event = EKEvent(eventStore: eventStore)
        event.title = task.title
        event.startDate = task.startTime
        event.endDate = task.endTime
        event.notes = task.notes
        event.calendar = calendar
        if !task.category.isEmpty { event.location = task.category }

        do {
            try eventStore.save(event, span: .thisEvent)
            let eventId = event.eventIdentifier
            UserDefaults.standard.set(eventId, forKey: "calendarEventId_\(task.id.uuidString)")
            print("✅ 任务已同步到日历: \(task.title)")
            return eventId
        } catch {
            print("❌ 同步到日历失败: \(error)")
            return nil
        }
    }

    func updateTaskInCalendar(eventId: String, task: DailyTask) {
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

    func addDDLToReminders(_ ddl: DDLProject) -> String? {
        guard isRemindersSyncEnabled, let reminderList = defaultReminderList else { return nil }

        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = ddl.title
        reminder.notes = ddl.notes
        reminder.calendar = reminderList

        let dueDateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: ddl.deadline
        )
        reminder.dueDateComponents = dueDateComponents

        for reminderSetting in ddl.reminderSettings {
            addAlarmToReminder(reminder, setting: reminderSetting, deadline: ddl.deadline)
        }

        do {
            try eventStore.save(reminder, commit: true)
            let reminderId = reminder.calendarItemIdentifier
            UserDefaults.standard.set(reminderId, forKey: "reminderItemId_\(ddl.id.uuidString)")
            print("✅ DDL 已同步到提醒事项: \(ddl.title)")
            return reminderId
        } catch {
            print("❌ 同步到提醒事项失败: \(error)")
            return nil
        }
    }

    func updateDDLInReminders(reminderId: String, ddl: DDLProject) {
        guard isRemindersSyncEnabled else { return }

        if let reminder = eventStore.calendarItem(withIdentifier: reminderId) as? EKReminder {
            reminder.title = ddl.title
            reminder.notes = ddl.notes

            let dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: ddl.deadline
            )
            reminder.dueDateComponents = dueDateComponents
            reminder.isCompleted = ddl.isCompleted
            if ddl.isCompleted { reminder.completionDate = Date() }

            if let alarms = reminder.alarms {
                for alarm in alarms { reminder.removeAlarm(alarm) }
            }
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
        case .oneHourBefore:   timeInterval = -3600
        case .oneDayBefore:    timeInterval = -86400
        case .threeDaysBefore: timeInterval = -259200
        case .oneWeekBefore:   timeInterval = -604800
        case .custom:
            if let days = setting.customDays { timeInterval = -Double(days * 86400) }
        }
        let alarm = EKAlarm(absoluteDate: deadline.addingTimeInterval(timeInterval))
        reminder.addAlarm(alarm)
    }

    // MARK: - 同步开关

    func toggleCalendarSync(enabled: Bool, completion: @escaping @Sendable (Bool) -> Void) {
        if enabled {
            if isCalendarGranted {
                isCalendarSyncEnabled = true
                saveSyncSettings()
                if defaultCalendar == nil { setupDefaultCalendar() }
                completion(true)
            } else {
                requestCalendarAccess { granted, _ in
                    DispatchQueue.main.async {
                        if granted {
                            self.isCalendarSyncEnabled = true
                            self.saveSyncSettings()
                        }
                        completion(granted)
                    }
                }
            }
        } else {
            isCalendarSyncEnabled = false
            saveSyncSettings()
            completion(true)
        }
    }

    func toggleRemindersSync(enabled: Bool, completion: @escaping @Sendable (Bool) -> Void) {
        if enabled {
            if isRemindersGranted {
                isRemindersSyncEnabled = true
                saveSyncSettings()
                if defaultReminderList == nil { setupDefaultReminderList() }
                completion(true)
            } else {
                requestRemindersAccess { granted, _ in
                    DispatchQueue.main.async {
                        if granted {
                            self.isRemindersSyncEnabled = true
                            self.saveSyncSettings()
                        }
                        completion(granted)
                    }
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

    func syncAllTasksToCalendar(_ tasks: [DailyTask]) {
        guard isCalendarSyncEnabled else { return }
        for task in tasks { _ = addTaskToCalendar(task) }
    }

    func syncAllDDLsToReminders(_ ddls: [DDLProject]) {
        guard isRemindersSyncEnabled else { return }
        for ddl in ddls { _ = addDDLToReminders(ddl) }
    }
}

// MARK: - DailyTask 扩展

extension DailyTask {
    var calendarEventId: String? {
        UserDefaults.standard.string(forKey: "calendarEventId_\(id.uuidString)")
    }
}

// MARK: - DDLProject 扩展

extension DDLProject {
    var reminderItemId: String? {
        UserDefaults.standard.string(forKey: "reminderItemId_\(id.uuidString)")
    }
}