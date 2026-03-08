import SwiftUI

struct NotificationSettingsView: View {
    @ObservedObject private var nm = NotificationManager.shared
    @AppStorage("taskReminderEnabled") private var taskReminderEnabled = true
    @AppStorage("deadlineReminderEnabled") private var deadlineReminderEnabled = true

    var body: some View {
        List {
            Section {
                NotificationPermissionRow()
            }

            if nm.isAuthorized {
                Section(header: Text("提醒类型")) {
                    Toggle("任务开始提醒", isOn: $taskReminderEnabled)
                    Toggle("截止时间提醒", isOn: $deadlineReminderEnabled)
                }

                Section {
                    Button("测试通知") {
                        sendTestNotification()
                    }
                    .foregroundColor(.blue)

                    Button("清除所有通知", role: .destructive) {
                        nm.cancelAllNotifications()
                        nm.clearBadge()
                    }
                }
            }
        }
        .navigationTitle("通知设置")
    }

    private func sendTestNotification() {
        // 创建一个测试任务（仅用于触发通知）
        struct TestTask: NotifiableTask {
            var id = UUID()
            var title = "测试任务"
            var startTime = Date().addingTimeInterval(60)  // 1分钟后
            var deadlineDate: Date? = Date().addingTimeInterval(120)
            var isCompleted = false
        }
        let test = TestTask()
        nm.scheduleTaskNotification(for: test)
        nm.scheduleDeadlineNotification(for: test)
    }
}