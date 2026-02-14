import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    // 请求通知权限
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ 通知权限已授予")
            } else if let error = error {
                print("❌ 通知权限请求失败: \(error.localizedDescription)")
            }
        }
    }
    
    // 为任务安排通知
    func scheduleNotification(for task: Task) {
        let content = UNMutableNotificationContent()
        content.title = "任务提醒"
        content.body = "该开始：\(task.title)"
        content.sound = .default
        
        // 设置触发时间
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: task.startTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        // 创建请求
        let request = UNNotificationRequest(
            identifier: task.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        // 添加通知
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 通知安排失败: \(error.localizedDescription)")
            } else {
                print("✅ 已为任务 '\(task.title)' 安排通知")
            }
        }
    }
    
    // 取消任务的通知
    func cancelNotification(for taskId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [taskId.uuidString])
        print("🗑️ 已取消任务通知")
    }
    
    // 取消所有通知
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("🗑️ 已取消所有通知")
    }
    
    // 检查待发送的通知（用于调试）
    func checkPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("📋 待发送的通知数量: \(requests.count)")
            for request in requests {
                print("  - \(request.content.body)")
            }
        }
    }
}
