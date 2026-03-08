import Foundation
import Combine
import _Concurrency
import UserNotifications
import UIKit

// MARK: - NotifiableTask 协议
// 你的任务模型（不管叫 Task / DailyTask / TaskItem）
// 只要遵循这个协议，通知管理器就能用
protocol NotifiableTask {
    var id: UUID { get }
    var title: String { get }
    var startTime: Date { get }
    var deadlineDate: Date? { get }
    var isCompleted: Bool { get }
}

// MARK: - NotificationManager（完整修复版）
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false

    private let center = UNUserNotificationCenter.current()

    private init() {
        checkAuthorizationStatus()
    }

    // MARK: - 1. 权限请求（async 版，主线程更新状态）
    func requestAuthorization() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run { self.isAuthorized = granted }
            if !granted {
                await MainActor.run { self.openSettings() }
            }
        } catch {
            print("❌ 通知权限请求失败: \(error)")
        }
    }

    // MARK: - 2. 检查权限状态
    func checkAuthorizationStatus() {
        center.getNotificationSettings { settings in
            // ✅ 在回调线程先取出值类型（UNAuthorizationStatus 是 enum，Sendable 安全）
            let authorized = settings.authorizationStatus == .authorized
            DispatchQueue.main.async {
                self.isAuthorized = authorized
            }
        }
    }

    // MARK: - 3. 任务开始提醒（准时触发）
    func scheduleTaskNotification(for task: any NotifiableTask) {
        guard isAuthorized, !task.isCompleted else { return }

        let fireDate = task.startTime
        guard fireDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "任务提醒 ⏰"
        content.body = "「\(task.title)」现在开始"
        content.sound = .default
        content.badge = 1
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }

        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(
            identifier: "task-\(task.id.uuidString)",
            content: content, trigger: trigger)

        center.add(request) { error in
            if let e = error { print("❌ 任务通知失败: \(e)") }
            else { print("✅ 任务通知已设置：\(fireDate.formatted())") }
        }
    }

    // MARK: - 4. DDL 三档提醒（1小时前 / 15分钟前 / 到点）
    func scheduleDeadlineNotification(for task: any NotifiableTask) {
        guard isAuthorized, !task.isCompleted,
              let deadline = task.deadlineDate, deadline > Date() else { return }

        let alerts: [(TimeInterval, String, String, String)] = [
            (60*60,  "ddl-1h",  "⚡ DDL 提醒",   "「\(task.title)」还有 1 小时截止"),
            (15*60,  "ddl-15m", "⚡ DDL 提醒",   "「\(task.title)」还有 15 分钟截止！快完成吧 💪"),
            (0,      "ddl-now", "⏰ 截止时间到", "「\(task.title)」已到截止时间"),
        ]

        for (before, suffix, title, body) in alerts {
            let fireDate = deadline.addingTimeInterval(-before)
            guard fireDate > Date() else { continue }

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = before == 0 ? .defaultCritical : .default
            content.badge = 1
            if #available(iOS 15.0, *) {
                content.interruptionLevel = before == 0 ? .critical : .timeSensitive
            }

            let comps = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(
                identifier: "\(suffix)-\(task.id.uuidString)",
                content: content, trigger: trigger)

            center.add(request) { error in
                if let e = error { print("❌ DDL 通知失败: \(e)") }
                else { print("✅ DDL 通知已设置：\(body)") }
            }
        }
    }

    // MARK: - 5. 同时设置任务 + DDL 通知
    func reschedule(for task: any NotifiableTask) {
        cancelNotifications(for: task.id)
        scheduleTaskNotification(for: task)
        scheduleDeadlineNotification(for: task)
    }

    // MARK: - 6. 取消指定任务的所有通知
    func cancelNotifications(for taskId: UUID) {
        let ids = [
            "task-\(taskId.uuidString)",
            "ddl-1h-\(taskId.uuidString)",
            "ddl-15m-\(taskId.uuidString)",
            "ddl-now-\(taskId.uuidString)",
        ]
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - 7. 取消所有
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    // MARK: - 8. 清除角标
    func clearBadge() {
        if #available(iOS 16.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(0) { _ in }
        } else {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }

    // MARK: - 9. 调试
    func debugPending() {
        center.getPendingNotificationRequests { reqs in
            print("📋 待发通知（\(reqs.count)条）")
            for r in reqs {
                if let t = r.trigger as? UNCalendarNotificationTrigger {
                    print("  [\(r.identifier)] \(r.content.body) → \(t.nextTriggerDate()?.formatted() ?? "-")")
                }
            }
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - 通知权限行（设置页直接使用）
import SwiftUI

struct NotificationPermissionRow: View {
    @ObservedObject private var nm = NotificationManager.shared

    var body: some View {
        HStack {
            Label("通知提醒", systemImage: nm.isAuthorized ? "bell.fill" : "bell.slash.fill")
                .foregroundColor(nm.isAuthorized ? .primary : .secondary)
            Spacer()
            if nm.isAuthorized {
                Text("已开启").font(.system(size: 13)).foregroundColor(.green)
            } else {
                Button("去开启") {
                    Task { await nm.requestAuthorization() }
                }
                .font(.system(size: 13, weight: .medium))
            }
        }
        .onAppear { nm.checkAuthorizationStatus() }
    }
}